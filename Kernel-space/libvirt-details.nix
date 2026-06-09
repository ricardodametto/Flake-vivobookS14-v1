# ==============================================================================
# kernel-space/libvirt-details.nix
#
# Camada de virtualização de plataforma — libvirt / QEMU / SPICE:
#   • Daemon libvirtd (KVM/QEMU backend)
#   • SPICE (clipboard, resolução dinâmica, USB redirection)
#   • Pacotes de gerenciamento e inspeção de VMs
#
# O que NÃO pertence aqui:
#   • Módulos e parâmetros de kernel (kernel-space/virtualization.nix)
#   • Conteinerização (Docker, Podman)
#   • Configuração de rede do host
# ==============================================================================

{ config, pkgs, pkgs-unstable,lib, ... }:

{
  # ============================================================
  # Libvirt — daemon KVM/QEMU
  # ============================================================
  virtualisation.libvirtd = {
    enable = true;
    allowedBridges = [ "br0" "virbr0" ];
    qemu = {
      package    = pkgs-unstable.qemu_kvm;
      runAsRoot  = true;
      swtpm.enable = true;
    };
  };

  # ============================================================
  # SPICE — integração host ↔ VM
  # ============================================================
  services.spice-vdagentd.enable        = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # ============================================================
  # Pacotes de gerenciamento de VMs
  # ============================================================
  environment.systemPackages = with pkgs-unstable; [
    # Gerenciamento KVM / libvirt
    virt-manager
    virt-viewer
    virt-top
    libguestfs

    # SPICE
    spice
    spice-gtk
    spice-vdagent

    # UEFI / Firmware
    virtio-win
    qemu-utils
    cloud-utils
    edk2
    seabios
    swtpm
    libvirt-glib
    qemu_full

    # UI alternativa
    gnome-boxes

    # Looking Glass (compartilhamento de framebuffer GPU)
    looking-glass-client
  ];

  # Virt-Manager conecta ao sistema por padrão
  environment.variables = {
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };
}