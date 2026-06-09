# ==============================================================================
# Gnome-Environment/core.nix
#
# Configurações base do GNOME, Shell e ferramentas essenciais.
# ==============================================================================

{ config, pkgs, pkgs-unstable, lib, ... }:

{
  # --- Display Manager + GNOME Shell ---
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # --- Shell (zsh) ---
  programs.zsh.enable = true;
  
  # --- direnv + nix-direnv ---
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # --- SSH gráfico (GNOME keyring / SSH agent) ---
  programs.seahorse.enable = true;

  # --- Pacotes essenciais do sistema ---
  environment.systemPackages = with pkgs-unstable; [
    gnome-tweaks
    gnome-software
    gnome-extension-manager
    gedit
    ptyxis
    kitty
    wl-clipboard
    curl
    wget
    git
  ];
}
