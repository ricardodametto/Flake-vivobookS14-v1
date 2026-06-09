# ==============================================================================
# Gnome-Environment/development.nix
#
# Linguagens de programação, compiladorese ferramentas de CLI para desenvolvimento com agentes de IA.
# ==============================================================================

{ config, pkgs, pkgs-unstable, lib, ... }:

{
  environment.systemPackages = with pkgs-unstable; [
    # --- Desenvolvimento ---
    python3
    gcc
    openjdk25
    devenv
    claude-code
    gemini-cli
  ];
}
