# ==============================================================================
# Gnome-Environment/pnetlab.nix
#
# Integração PNETLab — launcher de protocolos (telnet, vnc, wireshark).
# ==============================================================================

{ config, pkgs, pkgs-unstable, lib, ... }:

let
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

in
{
  environment.systemPackages = [
    pnet-launcher
    pnet-desktop-item
  ];
}

