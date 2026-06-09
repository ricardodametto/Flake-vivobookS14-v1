# ==============================================================================
# Gnome-Environment/home.nix
#
# Configuração do usuário via Home Manager:
#   • Pacotes pessoais (Spotify, Discord, Telegram)
#   • Tema GTK / ícones
#   • ZSH com plugins (Powerlevel10k, autopair, git aliases)
#   • Bash (necessário para scripts de sistema)
#
# O que NÃO pertence aqui:
#   • Habilitação do zsh no sistema → gnome-system.nix
#     (programs.zsh.enable = true no NixOS é obrigatório para adicionar
#      o zsh ao /etc/shells e permitir login shell via PAM. Sem isso o
#      shell não carrega corretamente mesmo com o HM configurado.)
#   • direnv hook — já injetado automaticamente pelo módulo NixOS
#     (programs.direnv.enableZshIntegration = true em gnome-system.nix
#      gera o eval "$(direnv hook zsh)" no .zshrc. Não duplicar aqui.)
# ==============================================================================

{ config, pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs; [
    # Fonte Meslo com Nerd Glyphs — necessária para o Powerlevel10k
    meslo-lgs-nf
  ];

  # Necessário para o Home Manager registrar as fontes no fontconfig do usuário
  fonts.fontconfig.enable = true;

  # ============================================================
  # Tema GTK / Ícones
  # ============================================================
  gtk = {
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # ============================================================
  # ZSH — configuração do usuário
  #
  # Nota: programs.zsh.enable = true também está declarado no NixOS
  # (gnome-system.nix). Isso é intencional e obrigatório:
  #   • NixOS: registra o zsh no /etc/shells e gera o /etc/zshrc base
  #   • Home Manager: configura plugins, prompt e initContent do usuário
  # Os dois precisam coexistir para o login shell funcionar corretamente.
  # ============================================================
  programs.zsh = {
    enable                   = true;
    autosuggestion.enable    = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "zsh-autopair";
        src  = pkgs.zsh-autopair;
        file = "share/zsh/zsh-autopair/autopair.zsh";
      }
      {
        name = "powerlevel10k";
        src  = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "git-aliases";
        src  = "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git";
        file = "git.plugin.zsh";
      }
    ];

    initContent = ''
      # Carrega a configuração do Powerlevel10k (prompt instantâneo)
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # Nota: o hook do direnv NÃO é inicializado aqui.
      # O módulo NixOS (programs.direnv.enableZshIntegration = true)
      # já injeta o eval "$(direnv hook zsh)" automaticamente no .zshrc.
    '';
  };

  # Bash habilitado para compatibilidade com scripts de sistema
  programs.bash.enable = true;

  home.stateVersion = "26.05";
}