# ==============================================================================
# Garbage-Collector/garbage.nix
#
# Configurações do gerenciador de pacotes Nix:
#   • Features experimentais (nix-command, flakes)
#   • Coleta de lixo automática semanal
#   • Versão de estado do sistema
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  # ============================================================
  # Nix — features e configurações globais
  # ============================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ============================================================
  # Garbage Collector — limpeza automática semanal
  # Remove gerações com mais de 7 dias do store do Nix
  # ============================================================
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 7d";
  };

  # ============================================================
  # Versão de estado do sistema
  # Não alterar após a instalação inicial
  # ============================================================
  system.stateVersion = "26.05";
}