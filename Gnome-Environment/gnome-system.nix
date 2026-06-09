# ==============================================================================
# Gnome-Environment/gnome-system.nix
#
# Agregador do ambiente GNOME — divide responsabilidades em módulos menores.
# ==============================================================================

{ ... }:

{
  imports = [
    ./core.nix
    ./extensions.nix
    ./pnetlab.nix
    ./apps.nix
    ./system-tools.nix
    ./development.nix
  ];
}
