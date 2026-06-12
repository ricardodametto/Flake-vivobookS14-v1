# ==============================================================================
# user/user.nix
#
# Identidade e permissões do usuário do sistema
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  users.groups.ricardo = {};         # ← adiciona
  
  users.users.ricardo = {
    isNormalUser = true;
    group = "ricardo";
    description  = "Ricardo";
    shell        = pkgs.zsh;
    extraGroups  = [
      "wheel"           # sudo
      "networkmanager"  # gerenciar redes via NM
      "audio"           # ALSA/PipeWire direto
      "video"           # acesso a /dev/dri, /dev/fb
      "render"
      "input"           # /dev/input/* (teclado, mouse)
      "disk"            # /dev/sd*, acesso a blocos
      "kvm"             # /dev/kvm
      "libvirtd"        # socket do libvirtd
      "qemu-libvirtd"   # processo QEMU sem root
      "docker"          # socket do Docker
      "wireshark"       # captura de pacotes sem root
    ];
  };

  nix.settings.trusted-users = [ "root" "ricardo" "wireshark" "qemu-libvirtd" "libvirtd" "kvm" "networkmanager" "video" "render" ];

  # ============================================================
  # Teclado / Locale / Console
  # ============================================================
  console.keyMap = "br-abnt2";
  services.xserver.xkb.layout = "br";
  services.xserver.xkb.variant = "";
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";
}