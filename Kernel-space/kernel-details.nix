# ==============================================================================
# kernel-space/kernel-details.nix
#
# Camada de abstração de hardware — tudo que vive "abaixo" do userspace:
#
#   • Kernel e seus parâmetros (boot, GPU, CPU, SSD, suspend, virtualização)
#   • Módulos e opções do modprobe
#   • Sysctl (VM + rede)
#   • Firmware, microcode e drivers de hardware
#   • GPU (OpenGL/Vulkan/VAAPI)
#   • Áudio (SOF / PipeWire)
#   • Rede física (Wi-Fi, Bluetooth)
#   • Serviços de suporte ao hardware (fwupd, fstrim)
#
# O que NÃO pertence aqui:
#   • Pacotes de usuário
#   • Serviços de aplicação (containers, libvirt daemons, etc.)
#   • Configuração do Home Manager
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  # ============================================================
  # Identidade do host
  # ============================================================
  networking.hostName = "vivobook-s14";


  # ============================================================
  # Kernel — Linux 7.x (Arrow Lake nativo)
  # ============================================================
  # nixpkgs 26.05 já inclui o 7.x; fallback para `latest` se o slot
  # específico não estiver disponível ainda.
  boot.kernelPackages = pkgs.linuxPackages_7_0 or pkgs.linuxPackages_latest;

  # ============================================================
  # Parâmetros de kernel — consolidados (configuration + virtualization)
  # NixOS faz merge automático de listas; mantemos aqui como fonte única
  # para facilitar auditoria e evitar surpresas de ordenação.
  # ============================================================
  boot.kernelParams = [

    # --- GPU Intel Arc 130T (Arrow Lake-P / driver `xe`) ---
    # O driver `xe` é o padrão no kernel 7.x para Arrow Lake.
    # Forçamos a probe explícita para evitar fallback para i915.
    "i915.force_probe=!7d51"
    "xe.force_probe=7d51"
    # "i915.enable_guc=3"         # Habilita GuC/HuC via i915 (fallback)

    # --- CPU / Power (P-core + E-core + LP-core) ---
    "intel_pstate=active"           # Gerenciamento de energia híbrido Intel

    # --- SSD / NVMe ---
    "nvme.noacpi=1"                 # Evita delays ACPI em NVMe (AMI/ASUS)
    "acpi_osi=Linux"                # Melhor compatibilidade ACPI geral

    # --- Mitigações de segurança ---
    "mitigations=auto"              # Kernel decide performance vs. segurança

    # --- Suspend / Resume ---
    # Arrow Lake: s2idle tem menor drain; troque para "s2idle" se "deep" causar problemas
    "mem_sleep_default=deep"

    # --- Virtualização / IOMMU (Intel VT-d) ---
    "intel_iommu=on"
    "iommu=pt"                      # Pass-through mode — menor overhead para o host

    # --- AppArmor / namespaces não-privilegiados ---
    "unprivileged_userns_apparmor_policy=default"

    # Notas de VFIO:
    # RTL8852BE (Wi-Fi) — BDF: 0000:01:00.0 | IDs: 10ec:b852 | IOMMU group 13
    # Sem vinculação permanente ao vfio-pci; passthrough sob demanda.
    # Ver procedimento no README do flake.
  ];

  # ============================================================
  # Módulos do kernel
  # ============================================================
  boot.kernelModules = [
    "kvm-intel"     # Virtualização Intel VT-x
    "vfio-pci"      # Passthrough de dispositivos PCIe
    "tun"           # Túneis (WireGuard, OpenVPN)
    "bridge"        # Bridging de rede virtual (libvirt NAT/bridge)
    "vhost_net"     # Aceleração de rede para VMs (virtio)
    "wireguard"     # VPN WireGuard nativa
  ];

  boot.extraModulePackages = [ ];

  # ============================================================
  # Opções de modprobe — KVM aninhado
  # ============================================================
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  # ============================================================
  # Sysctl — VM (NVMe + 32GB RAM) e rede
  # ============================================================
  boot.kernel.sysctl = {

    # --- Gerenciamento de memória virtual ---
    "vm.swappiness"               = 20;    # Moderado; RAM abundante
    "vm.vfs_cache_pressure"       = 50;    # Preserva cache de metadados
    "vm.dirty_ratio"              = 15;    # NVMe aguenta bursts maiores
    "vm.dirty_background_ratio"   = 5;     # Flush antecipado evita picos
    "vm.dirty_expire_centisecs"   = 3000;  # 30 s — adequado para SSD

    # --- Roteamento / forwarding ---
    "net.ipv4.ip_forward"          = 1;    # Necessário para WireGuard e VMs
    "net.ipv6.conf.all.forwarding" = 1;

    # --- Reverse Path Filter ---
    # Desativado para permitir que o Winbox receba respostas de 0.0.0.0
    # antes de o MikroTik ter IP configurado.
    "net.ipv4.conf.all.rp_filter"      = 0;
    "net.ipv4.conf.default.rp_filter"  = 0;
    "net.ipv4.conf.eth-usb.rp_filter"  = 0;
    "net.ipv4.conf.wlp1s0.rp_filter"   = 0;

    # --- Aceitar pacotes de endereços locais ---
    # Essencial para descoberta Winbox (Layer 2 / broadcast).
    "net.ipv4.conf.all.accept_local" = 1;

    # --- Containers rootless (Podman / Docker sem root) ---
    "user.max_user_namespaces" = 10000;

    # --- AppArmor / namespaces não-privilegiados ---
    "unprivileged_userns_apparmor_policy" = lib.mkDefault "default";
  };

  # ============================================================
  # Firmware & Microcode Intel
  # ============================================================
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  # SOF (Sound Open Firmware) — DSP Arrow Lake cAVS / codec Realtek ALC256
  hardware.firmware = with pkgs; [
    sof-firmware
    alsa-firmware
  ];

  # ============================================================
  # GPU — Intel Arc 130T (driver `xe`, kernel 7.x)
  # ============================================================
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;       # Compatibilidade Steam / Wine
    extraPackages = with pkgs; [
      intel-media-driver      # VAAPI iHD (Arc / Xe)
      intel-vaapi-driver      # Fallback i965
      libvdpau-va-gl          # VDPAU → VAAPI bridge
      vpl-gpu-rt              # Intel VPL (codec acelerado)
      intel-compute-runtime   # OpenCL (IA / edição de vídeo)
    ];
  };

  # Força o driver VAAPI correto no ambiente gráfico
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";  # intel-media-driver, não o legado i965
  };

  # ============================================================
  # Áudio — PipeWire + SOF (Arrow Lake)
  # ============================================================
  # Driver de kernel: `sof-audio-pci-intel-mtl`
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;

  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    jack.enable       = true;
    wireplumber.enable = true;
  };

  # ============================================================
  # Rede física — Wi-Fi 6 (RTL8852BE / rtw89) + Bluetooth
  # ============================================================
  # O firmware do RTL8852BE está coberto por `enableRedistributableFirmware`.
  networking.networkmanager.enable = true;
  networking.wireless.enable       = true;   # NM gerencia o Wi-Fi
  # Para alternar para iwd descomente:
  # networking.wireless.enable            = lib.mkForce false;
  # networking.networkmanager.wifi.backend = "iwd";
  # networking.wireless.iwd.enable         = true;

  hardware.bluetooth.enable      = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable        = true;

  # ============================================================
  # Serviços de suporte ao hardware
  # ============================================================
  services.fwupd.enable = true;   # Atualização de firmware (BIOS, NVMe, etc.)
  services.fstrim.enable = true;  # TRIM semanal — wear-leveling do NVMe
}