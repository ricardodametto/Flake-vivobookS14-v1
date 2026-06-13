# Vulkan e a abstração de driver: do userspace ao `xe`

> Documento de referência montado a partir do diagnóstico da iGPU Intel Arc
> (Arrow Lake) no vivobook-s14, rodando Ollama com backend Vulkan no NixOS.
> Foco: entender **como uma aplicação em userland fala com a GPU sem nunca
> saber qual driver roda por baixo.**

---

## A ideia central

**Vulkan é uma especificação, não um software.** É um contrato publicado pela
Khronos que diz: "uma API Vulkan deve ter estas funções, que se comportam
assim". Quem *implementa* esse contrato para um hardware específico é o driver
do fabricante.

No caso da Arc Arrow Lake, a implementação Vulkan da Intel chama-se **ANV** e
faz parte do **Mesa**. Quando algo "usa Vulkan" nesta máquina, está, no fim,
conversando com o ANV — que traduz comandos Vulkan genéricos em instruções que
a Arc entende.

A consequência prática dessa separação é **desacoplamento total**: a aplicação
é escrita uma vez, em Vulkan genérico, e roda em Intel, AMD, NVIDIA ou celular
sem alterar uma linha. Trocar a GPU não exige recompilar o app — só muda qual
driver o sistema apresenta.

---

## A inversão importante

A intuição ingênua é "o app quer falar com a GPU Intel". **Errado, e a correção
é o ponto-chave:**

- O app **não** quer falar com a Intel. O app quer falar **Vulkan, ponto.**
- Ele nem sabe (nem quer saber) que do outro lado há uma Intel.
- Quem decide *qual* driver atende é o **loader**, não o app.

Em forma de diálogo de três partes:

| Quem | Diz |
|------|-----|
| **App** (Ollama) | "Quero falar Vulkan. Não me interessa com quem." |
| **Loader** (`libvulkan.so`) | "Beleza. Quem aqui fala Vulkan? Achei o ANV (Intel). Te conecto com ele." |
| **ANV** (driver) | "Eu falo Vulkan pra fora e Arc-Arrow-Lake pra dentro. Manda que eu traduzo." |

A Intel só aparece **no fim da cadeia**, escondida do app de propósito. O app
esbarra apenas na "recepção" (o loader) pedindo "alguém que fale Vulkan", e a
recepção escolhe quem atende.

---

## A pilha completa, de cima para baixo

```
┌─────────────────────────────────────────────────────────┐
│ 1. APLICAÇÃO  (Ollama / ggml-vulkan)                      │  userspace
│    "aloca buffer, compila shader, despacha compute"       │
│    — fala Vulkan genérico, zero código Intel-específico   │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│ 2. LOADER  (libvulkan.so — pacote vulkan-loader)          │  userspace
│    — leu os ICDs (.json em icd.d/) no startup             │
│    — descobre quais drivers existem e roteia a chamada    │
│    ←── VK_DRIVER_FILES tranca a escolha no ICD da Intel   │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│ 3. ANV  (driver Vulkan da Intel, dentro do Mesa)          │  userspace
│    — compila os shaders SPIR-V → ISA nativa da Arc        │
│    — monta os command buffers (comandos binários da GPU)  │
└───────────────────────────┬─────────────────────────────┘
                            │  ioctl() sobre /dev/dri/renderD128
══════════════════════════ │ ════════ FRONTEIRA USER/KERNEL ═══════════
                            │  (uma syscall — userspace pede ao kernel)
┌───────────────────────────▼─────────────────────────────┐
│ 4. DRIVER xe  (kernel)                                    │  kernel space
│    — gerencia memória da GPU (RAM compartilhada, sem VRAM)│
│    — mapeia memória processo↔GPU via IOMMU (VT-d)         │
│    — submete command buffers às engines do hardware       │
│    — sincronização, fences, interrupções                  │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│ 5. SILÍCIO  (Intel Arc 130T — Xe-LPG, Arrow Lake)         │  hardware
│    — executa o compute de fato (multiplicações de matriz) │
└─────────────────────────────────────────────────────────┘
```

### Detalhe de cada camada

**1. Aplicação.** Emite comandos Vulkan abstratos. Os shaders de compute (as
multiplicações de matriz da inferência) chegam aqui escritos em **SPIR-V**, o
bytecode padrão do Vulkan.

**2. Loader (`libvulkan.so`).** O app linka contra ele, não contra o driver. No
boot, o loader leu os arquivos **ICD** (*Installable Client Driver*) — cada um é
um `.json` em `icd.d/` que funciona como cartão de visita: "o driver X está
nesta `.so`". O loader é um despachante: enumera os drivers, deixa escolher um
device, e roteia as chamadas para o driver certo.

**3. ANV (Mesa).** Aqui mora a inteligência. Pega o comando Vulkan abstrato e o
**compila para a ISA da GPU específica** — o SPIR-V passa pelo compilador do
Mesa e vira instruções nativas da Arc. Monta os *command buffers*: listas de
comandos no formato binário que o Arrow Lake entende. Tudo ainda em userspace,
dentro do processo do app.

**4. Fronteira — o `ioctl`.** O ANV não toca o hardware diretamente (userspace
não tem permissão). Ele empacota os command buffers e faz uma **syscall**
(`ioctl()`) sobre o device node `/dev/dri/renderD128`. É o ponto exato onde sai
do userspace e entra no kernel.

**5. Driver `xe` (kernel).** Quem realmente toca o silício. Gerencia a memória
da GPU (no Arrow Lake, regiões da RAM compartilhada — não há VRAM dedicada, daí
os "~23 GiB de device memory" que o Ollama reporta), faz o mapeamento de memória
entre processo e GPU via IOMMU, recebe os command buffers e os submete às
engines de hardware (compute para o Ollama; vídeo para decode de mídia),
cuida de sincronização e interrupções.

O `xe` é a reescrita moderna do driver de kernel da Intel (sucessor do `i915`),
feita para Xe/Arc. Por ser novo, ferramentas de monitoramento da era `i915`
(nvtop antigo, `intel_gpu_top`) **ainda não leem a telemetria dele direito** —
motivo pelo qual a GPU pode aparecer como "0%" mesmo trabalhando.

---

## Onde a config se encaixa na pilha

As variáveis de ambiente do Ollama atuam em **camadas diferentes** e específicas
da pilha. Entender isso evita tratá-las como "magia que liga a GPU".

```nix
environmentVariables = {
  # Camada da APLICAÇÃO/backend — liga o backend Vulkan do ggml
  OLLAMA_VULKAN = "1";

  # Camada da APLICAÇÃO — destrava uso de iGPU (sem VRAM dedicada/UMA)
  OLLAMA_IGPU_ENABLE = "1";

  # Camada do ld.so (carregamento) — onde achar libvulkan.so e Mesa no NixOS
  LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";

  # Camada do LOADER Vulkan (seleção de driver) — força só o ICD Intel (ANV)
  VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
};
```

| Variável | Camada | Papel |
|----------|--------|-------|
| `OLLAMA_VULKAN` | App/backend | Liga o backend Vulkan; sem ela cai pra CPU |
| `OLLAMA_IGPU_ENABLE` | App | Destrava GPU integrada (ggml filtra GPUs sem VRAM dedicada) |
| `LD_LIBRARY_PATH` | `ld.so` (passo 2) | Resolve **onde** estão as bibliotecas (`libvulkan.so`, Mesa) |
| `VK_DRIVER_FILES` | Loader Vulkan (passo 2) | Resolve **qual** driver usar — tranca no ANV |

**As variáveis de path NÃO tocam o kernel nem o `xe`.** A metade userspace da
pilha (loader + ANV) é configurada aqui, no módulo do Ollama. A metade hardware
(passos 4-5) é configurada no kernel — `xe.force_probe=7d51`, `intel_iommu=on`.
As duas metades se encontram exatamente no `ioctl`.

### `LD_LIBRARY_PATH` vs `VK_DRIVER_FILES` — não são a mesma coisa

- **`LD_LIBRARY_PATH`** = endereço da loja de drivers. Genérico do Linux, não
  sabe o que é Vulkan. Sem ele, o app talvez nem ache `libvulkan.so` → "no
  Vulkan support" → CPU. É erro de **carregamento**.
  *(Pode ser redundante se o pacote já tiver rpath correto, mas custa zero.)*

- **`VK_DRIVER_FILES`** = apontar o dedo para o driver certo na prateleira.
  Específico do Vulkan, atua **depois** que o loader já carregou. Sem ele, o
  loader pode enumerar vários devices e o app pegar o errado. É erro de
  **seleção**. *(Nome novo de `VK_ICD_FILENAMES`, deprecado.)*

---

## A armadilha do lavapipe

O `VK_DRIVER_FILES` não é decoração — é proteção contra um falso positivo
silencioso e perigoso.

O **lavapipe** (`lvp_icd`) é uma implementação Vulkan **por software**: ela fala
Vulkan fluentemente, mas o "hardware" dela é a **CPU**. Se o loader enumerar
Intel + lavapipe e o app escolher o lavapipe, ele roda na CPU **achando que está
na GPU** — o log mostra "device Vulkan", tudo parece certo, e a performance é
péssima sem motivo aparente.

`VK_DRIVER_FILES` é o bilhete na recepção: **"só apresenta o tradutor Intel
(ANV), os outros nem menciona."** Garante que o device escolhido é a Arc de
verdade, não a CPU disfarçada.

---

## Resumo em uma frase

> Você é um app que quer rodar compute numa GPU? Não precisa saber qual. Fala
> **Vulkan** com a recepção (loader), que acha o tradutor certo para o hardware
> presente — aqui, o **ANV** da Intel — e te conecta. O tradutor vira isso em
> comandos que a Arc entende e passa, via `ioctl`, para o kernel (`xe`)
> executar no silício.

A regra mental que vale internalizar:

**Userspace escolhe e prepara o trabalho (loader + ANV). Kernel executa no
hardware (`xe`). A fronteira entre os dois é uma syscall.**

---

## Como verificar no sistema

```bash
# Ver o Ollama reconhecendo o Vulkan no carregamento
journalctl -u ollama -b | grep -iE "vulkan|ggml|device|backend|offloaded"

# Ver o loader Vulkan enumerar os ICDs ao vivo (camada 2 da pilha)
VK_LOADER_DEBUG=all <app-vulkan> 2>&1 | grep -iE "icd|driver|intel"

# Confirmar que a GPU está realmente ocupada (sysfs — independe de nvtop/xe)
watch -n0.5 'cat /sys/class/drm/card*/device/gpu_busy_percent'

# Listar os ICDs Vulkan instalados (quem o loader pode escolher)
ls /run/opengl-driver/share/vulkan/icd.d/
```

Sinais de que a pilha está funcionando ponto a ponto:
- `ggml_vulkan: Found N Vulkan devices` → loader enumerou (camada 2)
- `Intel(R) Graphics (ARL)` no device_info → ANV reportando a Arc (camada 3)
- `library=Vulkan` na linha de gpu memory → backend escolhido
- `offloaded 37/37 layers to GPU` → uso real, trabalho na GPU
- `gpu_busy_percent` subindo durante a inferência → silício ocupado (camada 5)
