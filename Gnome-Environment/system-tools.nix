# ==============================================================================
# Gnome-Environment/system-tools.nix
#
# Ferramentas de diagnóstico, monitoramento, rede e hardware.
# ==============================================================================

{ config, pkgs, pkgs-unstable, lib, ... }:

{
  # --- Wireshark (grupo dedicado) ---
  programs.wireshark.enable = true;

  environment.systemPackages = with pkgs-unstable; [
    # --- Rede ---
    wireshark
    wireguard-tools
    sshpass
    inetutils

    # --- Diagnóstico de hardware ---
    hardinfo2             # GUI estilo HWInfo
    inxi                  # specs no terminal
    fastfetch             # resumo visual

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
    pciutils              # lspci
    usbutils              # lsusb
    nvme-cli              # health do NVMe
    dmidecode             # info BIOS / RAM
    e2fsprogs
  ];
}
