# Flake NixOS — Vivobook S14

Configuração NixOS modular com Home Manager para Vivobook S14.

---

## Temas GTK e Engines de Renderização

### Por que alguns temas aparecem no Tweaks mas não podem ser aplicados?

O GTK (biblioteca que desenha os widgets das aplicações GNOME) suporta duas formas de temas:

#### Temas baseados em Engine (GTK2/GTK3 legado)

O arquivo de tema declara qual engine utilizar — por exemplo, `engine "murrine"` — e o GTK busca esse plugin compilado (um arquivo `.so`) no sistema em tempo de execução. Se o plugin não estiver instalado:

- O GNOME Tweaks **consegue listar o tema** (lê apenas os metadados do diretório)
- Ao tentar **aplicar**, o GTK não encontra o engine e falha silenciosamente
- O tema anterior permanece ativo sem nenhuma mensagem de erro

É o mesmo princípio de abrir um documento com uma fonte que não está instalada: o arquivo existe, mas a renderização falha e o sistema usa um fallback.

Engines mais comuns:

| Engine              | Pacote NixOS          | Usado por                          |
|---------------------|-----------------------|------------------------------------|
| `murrine`           | `gtk-engine-murrine`  | Orchis, WhiteSur, Colloid e outros |
| `clearlooks`, etc.  | `gtk-engines`         | Temas GTK2 legados                 |

#### Temas baseados em CSS (GTK3+ moderno)

O GTK3 introduziu um sistema de temas via CSS puro, sem plugins externos. O próprio GTK interpreta o CSS — qualquer instalação GTK3 consegue renderizá-lo sem dependência adicional.

Exemplos de temas CSS puros: `flat-remix-gtk-theme`, `adw-gtk3`.

> **GTK4 e libadwaita**: O GTK4 com libadwaita descontinuou completamente o suporte a engines. Apenas CSS é suportado, e aplicações GTK4 nativas ignoram temas GTK3 — seguem o esquema de cores do sistema (`prefer-dark` / `prefer-light`).

### No NixOS

Como o sistema é isolado por design, os engines **devem ser declarados explicitamente** como pacotes — eles não são instalados automaticamente junto com o tema. Em `gnome-extensions.nix`:

```nix
windowThemes = with pkgs; [
  orchis-theme
  whitesur-gtk-theme
  colloid-gtk-theme
  flat-remix-gtk-theme
  gtk-engine-murrine   # obrigatório para orchis, whitesur, colloid
  gtk-engines          # engines GTK2/3 complementares
];
```
