# ==============================================================================
# Gnome-Environment/development.nix
#
# Linguagens de programação e ferramentas de CLI para desenvolvimento.
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
