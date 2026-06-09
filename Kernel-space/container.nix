# ==============================================================================
# kernel-space/container.nix
#
# Camada de conteinerização — Docker / Podman / rootless:
#   • Docker daemon (IPv6, experimental)
#   • Podman (rootless, DNS nativo)
#   • Suporte a containers OCI compartilhado
#   • Pacotes de operação e observabilidade
#
# O que NÃO pertence aqui:
#   • Virtualização de plataforma (libvirtd, QEMU) → libvirt-details.nix
#   • Módulos de kernel (tun, bridge, vhost_net) → virtualization.nix
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  # ============================================================
  # Docker
  # ============================================================
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      ipv6            = true;
      fixed-cidr-v6   = "fd00::/80";
      experimental    = true;
    };
  };

  # ============================================================
  # Podman — rootless OCI
  # ============================================================
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Camada de armazenamento e runtime OCI compartilhada entre Docker e Podman
  virtualisation.containers.enable = true;

  # ============================================================
  # Pacotes de conteinerização
  # ============================================================
  environment.systemPackages = with pkgs; [
    # Compose / orquestração local
    docker-compose
    podman-compose

    # Inspeção e análise de imagens
    dive           # Explora camadas de imagem layer a layer
    skopeo         # Inspeciona/copia imagens entre registries sem daemon
    crane          # Ferramenta leve para manipular imagens OCIs

    # Observabilidade de containers
    ctop           # Top para containers (Docker/podman)
    lazydocker     # TUI completa para Docker

    # Integração com distros no host (rootless)
    distrobox

    # Redes de container
    cni-plugins    # Plugins CNI usados pelo Podman
    slirp4netns    # Rede rootless para Podman
    fuse-overlayfs # Overlay filesystem para containers rootless

    # Utilitários de sistema que complementam containers
    iproute2
    bridge-utils
    iptables
    nftables
  ];
}