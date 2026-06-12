# ==============================================================================
# Garbage-Collector/garbage.nix
#
# Configurações do gerenciador de pacotes Nix:
#   • Features experimentais (nix-command, flakes)
#   • Limpeza de gerações (mantém últimas 3) + GC, a cada ~3 dias de uso
#   • Versão de estado do sistema
# ==============================================================================
{ config, pkgs, lib, ... }:
{
  # ============================================================
  # Nix — features e configurações globais
  # ============================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ============================================================
  # Limpeza de gerações — mantém apenas as últimas 3
  # e roda o garbage collector pra liberar espaço de fato
  # ============================================================
  systemd.services.nix-gc-generations = {
    description = "Limpar gerações antigas do NixOS (manter últimas 3) e coletar lixo";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nix-gc-generations" ''
        ${pkgs.nix}/bin/nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system
        ${pkgs.nix}/bin/nix-collect-garbage -d
      '';
    };
  };

  # ============================================================
  # Timer — roda ~10min após boot, repete a cada 3 dias de uso
  # Não depende de horário fixo, ideal para laptop com uso irregular
  # ============================================================
  systemd.timers.nix-gc-generations = {
    description = "Timer para limpar gerações antigas do NixOS";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec       = "10min";
      OnUnitActiveSec = "3d";
      Persistent      = true;
    };
  };

  # ============================================================
  # Versão de estado do sistema
  # Não alterar após a instalação inicial
  # ============================================================
  system.stateVersion = "26.05";
}