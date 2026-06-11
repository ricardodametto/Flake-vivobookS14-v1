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
    user-themes
  ];

  iconThemes = with pkgs-unstable; [
    papirus-icon-theme
    fluent-icon-theme
    tela-icon-theme
    zafiro-icons
    flat-remix-icon-theme
  ];

  windowThemes = with pkgs; [
    whitesur-gtk-theme   # clone macOS
    orchis-theme         # flat, moderno
    colloid-gtk-theme    # minimalista
    flat-remix-gtk       # versátil e moderno
    bibata-cursors       # cursor moderno
    gtk-engine-murrine   # engine exigido por orchis, whitesur e outros temas
  ];

in
{
  environment.systemPackages = gnomeExtensionsList ++ iconThemes ++ windowThemes;
}
