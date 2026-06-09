# ==============================================================================
# kernel-space/virtualization.nix
#
# Configurações de kernel relacionadas à virtualização:
#   • Módulos KVM/VFIO carregados na inicialização
#   • Parâmetros de kernel (IOMMU, VT-d)
#   • Opções de modprobe (nested virt, ignore_msrs)
#
# O que NÃO pertence aqui:
#   • Daemons de userspace (libvirtd, docker, podman)
#   • Pacotes de sistema
#   • Configuração de rede virtual (bridges, dnsmasq)
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  # ============================================================
  # Virtualização Aninhada — KVM Intel (VT-x + VT-d)
  # ============================================================
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  boot.kernelModules = [
    "kvm-intel"   # Virtualização Intel VT-x
    "vfio-pci"    # Passthrough de dispositivos PCIe
    "tun"         # Túneis (WireGuard, OpenVPN)
    "bridge"      # Bridging de rede virtual (libvirt NAT/bridge)
    "vhost_net"   # Aceleração de rede para VMs (virtio)
    "wireguard"   # VPN WireGuard nativa
  ];

  boot.extraModulePackages = [ ];

  # IOMMU / VT-d — necessário para passthrough de dispositivos
  # RTL8852BE (Wi-Fi): BDF 0000:01:00.0 | IDs 10ec:b852 | IOMMU group 13
  # Sem vinculação permanente ao vfio-pci; passthrough sob demanda.
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "unprivileged_userns_apparmor_policy=default"
  ];
}