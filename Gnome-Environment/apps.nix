# ==============================================================================
# Gnome-Environment/apps.nix
#
# Aplicativos de usuário final (Browsers, Editores e Ferramentas).
# ==============================================================================

{ config, pkgs, pkgs-unstable, lib, ... }:

{
  # --- KDE Connect via Valent ---
  programs.kdeconnect = {
    enable  = true;
    package = pkgs-unstable.valent;
  };

  environment.systemPackages = with pkgs-unstable; [
    # --- Browsers e editores ---
    vscodium
    vscode
    google-chrome

    # --- Ferramentas ---
    podman-desktop
    virt-viewer
    winbox          # Mantido conforme solicitação do usuário
  ];
}
