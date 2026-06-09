# ==============================================================================
# Gnome-Environment/extensions.nix
#
# Extensões do GNOME e temas de ícones.
# ==============================================================================

{ config, pkgs, pkgs-unstable, lib, ... }:

let
  gnomeExtensionsList = with pkgs-unstable.gnomeExtensions; [
    dash-to-dock
    system-monitor
    gsconnect
  ];

  iconThemes = with pkgs-unstable; [
    papirus-icon-theme
    fluent-icon-theme
    tela-icon-theme
    zafiro-icons
  ];

in
{
  environment.systemPackages = gnomeExtensionsList ++ iconThemes;
}
