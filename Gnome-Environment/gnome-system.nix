# ==============================================================================
# Gnome-Environment/gnome-system.nix
#
# Ambiente gráfico completo — GNOME + aplicações + shell:
#   • Display manager (GDM) e GNOME Shell
#   • Extensões, temas e ícones
#   • Integração PNETLab (launcher customizado)
#   • Aplicações de sistema e desenvolvimento
#   • Shell (zsh), direnv, wireshark, KDE Connect (Valent)
#
# O que NÃO pertence aqui:
#   • Drivers de GPU → kernel-space/kernel-details.nix
#   • Áudio (PipeWire) → kernel-space/kernel-details.nix
#   • Configuração de usuário/grupos → user/user.nix
# ==============================================================================

{ config, pkgs, pkgs-unstable, lib, ... }:

let
  # ============================================================
  # PNETLab — launcher de protocolos (telnet, vnc, wireshark)
  # ============================================================
  pnet-launcher = pkgs-unstable.writeShellScriptBin "pnet-launcher" ''
    URL=$1
    SCHEME=$(echo $URL | cut -d':' -f1)
    case "$SCHEME" in
      telnet)
        CLEAN_URL=$(echo $URL | sed 's/telnet:\/\///' | sed 's/:telnet//' | tr ':' ' ')
        ${pkgs-unstable.ptyxis}/bin/ptyxis -- bash -c "${pkgs-unstable.inetutils}/bin/telnet $CLEAN_URL"
        ;;
      vnc)
        ${pkgs-unstable.virt-viewer}/bin/remote-viewer $URL
        ;;
      pnetlab)
        HOST=$(echo $URL | cut -d'/' -f3)
        IFACE=$(echo $URL | rev | cut -d'/' -f1 | rev)
        ${pkgs-unstable.wireshark}/bin/wireshark -k -i <(${pkgs-unstable.openssh}/bin/ssh root@$HOST "tcpdump -U -i $IFACE -w -")
        ;;
    esac
  '';

  pnet-desktop-item = pkgs-unstable.makeDesktopItem {
    name        = "pnet-launcher";
    desktopName = "PNETLab Integration";
    exec        = "pnet-launcher %u";
    mimeTypes   = [
      "x-scheme-handler/pnetlab"
      "x-scheme-handler/telnet"
      "x-scheme-handler/vnc"
    ];
    noDisplay = true;
    type      = "Application";
  };

  # ============================================================
  # Extensões GNOME
  # ============================================================
  gnomeExtensionsList = with pkgs-unstable.gnomeExtensions; [
    dash-to-dock
    system-monitor
    gsconnect
  ];

  # ============================================================
  # Temas de ícones
  # ============================================================
  iconThemes = with pkgs-unstable; [
    papirus-icon-theme
    fluent-icon-theme
    tela-icon-theme
    zafiro-icons
  ];

in
{
  # ============================================================
  # Display Manager + GNOME Shell
  # ============================================================
  services.xserver.enable          = true;
  services.displayManager.gdm.enable        = true;
  services.desktopManager.gnome.enable      = true;

  # ============================================================
  # Shell — zsh
  # ============================================================
  programs.zsh.enable              = true;
  
  # ============================================================
  # direnv + nix-direnv
  # ============================================================
  programs.direnv = {
    enable               = true;
    nix-direnv.enable    = true;
    enableZshIntegration = true;
  };

  # ============================================================
  # Wireshark (grupo dedicado)
  # ============================================================
  programs.wireshark.enable        = true;

  # ============================================================
  # KDE Connect via Valent
  # ============================================================
  programs.kdeconnect = {
    enable  = true;
    package = pkgs-unstable.valent;
  };

  # ============================================================
  # Pacotes — GNOME, aplicações e ferramentas de desenvolvimento
  # ============================================================
  environment.systemPackages = (with pkgs-unstable; [

    # --- PNETLab ---
    pnet-launcher
    pnet-desktop-item

    # --- GNOME ---
    gnome-tweaks
    gnome-software
    gnome-extension-manager
    gedit
    ptyxis
    kitty

    # --- Browsers e editores ---
    vscodium
    vscode
    google-chrome

    # --- Virtualização / Rede ---
    podman-desktop
    virt-viewer
    winbox
    wireshark
    wireguard-tools
    sshpass
    inetutils

    # --- Clipboard ---
    wl-clipboard          # provider de clipboard para Neovim/Wayland

    # --- Diagnóstico de hardware ---
    hardinfo2             # GUI estilo HWInfo
    inxi                  # specs no terminal
    fastfetch             # resumo visual (sucessor do neofetch)

    # --- GPU / Aceleração ---
    mesa-demos            # glxinfo
    libva-utils           # vainfo
    vulkan-tools          # vulkaninfo
    intel-gpu-tools       # intel_gpu_top
    nvtopPackages.intel
    intel-compute-runtime

    # --- Monitoramento ---
    htop
    btop
    lm_sensors
    powertop
    iotop
    iftop
    nethogs
    sysstat

    # --- Utilitários de sistema ---
    wget
    git
    pciutils              # lspci
    usbutils              # lsusb
    nvme-cli              # health do NVMe
    dmidecode             # info BIOS / RAM
    e2fsprogs

    # --- Desenvolvimento ---
    python3
    gcc
    openjdk25
    devenv
    claude-code

  ]) ++ gnomeExtensionsList ++ iconThemes;

  # ============================================================
  # Variável para SSH gráfico (GNOME keyring / SSH agent)
  # ============================================================
  programs.seahorse.enable = true;
}