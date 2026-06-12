# ==============================================================================
# Firewall-Rules/firewall-rules.nix
#
# Configuração de rede e firewall do host:
#   • Otimização de boot (desativa wait-online)
#   • networkd + bridge br0 (USB-Ethernet para Winbox/Lab MikroTik)
#   • Firewall (portas WireGuard, SPICE, KDE Connect, libvirt DNS/DHCP)
#   • udev (renomeia eth-usb, RPF, wakeup, RTL8852BE Runtime PM)
#
# O que NÃO pertence aqui:
#   • Wi-Fi e Bluetooth físico → kernel-space/kernel-details.nix
#   • Parâmetros de kernel de rede (sysctl) → kernel-space/kernel-details.nix
#   • Módulos de kernel (tun, bridge, wireguard) → kernel-space/virtualization.nix
# ==============================================================================

{ pkgs, ... }:

{
  # ============================================================
  # Boot — evita travamento aguardando rede online
  # Necessário quando há interfaces opcionais (eth-usb, br0)
  # que nem sempre estão presentes na inicialização
  # ============================================================
  systemd.network.wait-online.enable = false;

  # ============================================================
  # Rede — networkd + firewall
  # useNetworkd = true delega o gerenciamento de interfaces ao
  # systemd-networkd; useDHCP = false evita conflito com o DHCP
  # declarado explicitamente nas redes abaixo
  # ============================================================
  networking = {
    useNetworkd = true;
    useDHCP     = false;

    firewall = {
      enable = true;

      # TCP — Zabbix (9090), SPICE/Looking Glass (7534)
      allowedTCPPorts = [ 9090 7534 ];

      # UDP — WireGuard (51820), custom (5678), Winbox discovery (20561),
      #        SPICE (7534), WireGuard alt (13231), KDE Connect (37179)
      allowedUDPPorts = [ 51820 5678 20561 7534 13231 37179 11434 ];

      # Necessário para WireGuard e rotas assimétricas (Winbox/Lab)
      checkReversePath = false;

      # KDE Connect / GSConnect — range de portas de transferência
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];

      # DNS (53) e DHCP (67) liberados apenas na bridge virbr0
      # Necessário para o dnsmasq do libvirt servir as VMs
      interfaces."virbr0" = {
        allowedTCPPorts = [ 53 67 ];
        allowedUDPPorts = [ 53 67 ];
      };

      # Interfaces confiáveis — sem filtragem de pacotes entre elas
      # virbr0/br0: bridges de VM | eth-usb: Winbox/Lab | wlp1s0: Wi-Fi
      trustedInterfaces = [ "virbr0" "br0" "eth-usb" "wlp1s0" ];
    };
  };

  # ============================================================
  # Networkd — bridge br0 (USB-Ethernet → Winbox / Lab MikroTik)
  #
  # STP desativado: o Spanning Tree Protocol introduz delay de ~30s
  # antes de liberar a porta; sem ele o DHCP dispara imediatamente.
  # Seguro para topologia com um único switch/roteador.
  # ============================================================
  systemd.network.netdevs."10-br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
    bridgeConfig.STP = false;
  };

  # br0 obtém IP via DHCP (IPv4); não bloqueia o boot se offline
  systemd.network.networks."10-br0" = {
    matchConfig.Name              = "br0";
    networkConfig.DHCP            = "ipv4";
    linkConfig.RequiredForOnline  = "no";
  };

  # eth-usb entra na bridge quando o adaptador USB-Ethernet aparecer
  # LinkLocalAddressing = "no" evita que o networkd atribua um
  # endereço link-local à interface membro da bridge
  systemd.network.networks."20-usb-eth" = {
    matchConfig.Name = "eth-usb";
    networkConfig = {
      Bridge              = "br0";
      LinkLocalAddressing = "no";
    };
    linkConfig.RequiredForOnline = "no";
  };

  # ============================================================
  # udev — regras de hardware e rede
  # ============================================================
  services.udev.extraRules = ''
    # Renomeia adaptador USB-Ethernet para nome fixo independente da porta USB
    # MAC 00:e0:4c:20:3e:a8 → eth-usb (necessário para as regras de firewall)
    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:e0:4c:20:3e:a8", NAME="eth-usb"

    # Desabilita RPF no adaptador Winbox/Lab ao aparecer
    # (complementa o sysctl rp_filter=0 do kernel-details.nix)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth-usb", RUN+="${pkgs.bash}/bin/bash -c 'echo 0 > /proc/sys/net/ipv4/conf/eth-usb/rp_filter'"

    # Desabilita RPF no Wi-Fi (RTL8852BE / wlp1s0)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlp1s0", RUN+="${pkgs.bash}/bin/bash -c 'echo 0 > /proc/sys/net/ipv4/conf/wlp1s0/rp_filter'"

    # Desabilita wakeup por USB — evita acordar o notebook com periféricos
    SUBSYSTEM=="usb", ATTR{power/wakeup}="disabled"

    # Desabilita wakeup pelo touchpad I2C
    SUBSYSTEM=="i2c", ATTR{power/wakeup}="disabled"

    # RTL8852BE — desabilita Runtime PM para evitar bug de resume do driver rtw89
    # Sem isso o Wi-Fi pode não recuperar após suspend/resume
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10ec", ATTR{device}=="0xb852", ATTR{power/control}="on"
  '';
}