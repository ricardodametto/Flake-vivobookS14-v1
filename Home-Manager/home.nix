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
    fzf
  ];

  # Necessário para o Home Manager registrar as fontes no fontconfig do usuário
  fonts.fontconfig.enable = true;

  # Configurações do GNOME via dconf comando dconf dump /org/gnome/desktop/interface/ e dconf dump /org/gnome/shell/
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "default";
      gtk-theme = "Orchis-Light";
      icon-theme = "Papirus";
      cursor-theme = "Bibata-Modern-Ice";
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Orchis-Light";
    };
  };


  # ============================================================
  # GPG + Password Store
  #
  # pass: gerenciador de secrets criptografados com GPG.
  # Uso: pass insert deepseek/api-key → armazena criptografado
  #      pass show deepseek/api-key   → descriptografa on-demand
  # Integra com direnv via: export VAR=$(pass show caminho/key)
  #
  # gpg-agent: cacheia a passphrase da chave GPG por 1h,
  # evitando prompt repetido a cada uso do direnv.
  # pinentry-gnome3: janela gráfica GTK para solicitar passphrase.
  # ============================================================
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable          = true;
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl = 3600;  # 1h — passphrase cacheada por sessão
    maxCacheTtl     = 86400; # 24h — máximo antes de pedir de novo
  };

  programs.password-store = {
    enable  = true;
    package = pkgs.pass;
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

  # ============================================================
  # Starship — presets disponíveis para alternância
  #
  # Os toml ficam em ~/.config/starship/
  # Alterna com a função fish: starship-theme <nome>
  # ============================================================
        
  home.file = {
    ".config/starship/tokyo-night.toml".source      = ./kitty-custom/starship/tokyo-night.toml;
    ".config/starship/pastel-powerline.toml".source = ./kitty-custom/starship/pastel-powerline.toml;
    ".config/starship/gruvbox-rainbow.toml".source  = ./kitty-custom/starship/gruvbox-rainbow.toml;
    ".config/starship/jetpack.toml".source          = ./kitty-custom/starship/jetpack.toml;
    ".config/starship/pure-preset.toml".source      = ./kitty-custom/starship/pure-preset.toml;
  };

  # ============================================================
  # Fish — shell exclusivo do Kitty com Starship
  #
  # Autosuggestion e syntax highlighting são nativos do fish.
  # Plugins adicionais via fishPlugins:
  #   • autopair       — fecha parênteses, aspas, colchetes
  #   • fzf-fish       — busca no histórico com Ctrl+R
  #   • abbr-tips      — lembra atalhos git quando digitas o comando longo
  # ============================================================
  programs.fish = {
    enable = true;

    plugins = [
      { name = "autopair";            src = pkgs.fishPlugins.autopair; }
      { name = "fzf-fish";            src = pkgs.fishPlugins.fzf-fish; }
      { name = "plugin-git";          src = pkgs.fishPlugins.plugin-git; }
      { name = "fish-you-should-use"; src = pkgs.fishPlugins.fish-you-should-use; }
      { name = "sponge";              src = pkgs.fishPlugins.sponge; }
      { name = "colored-man-pages";   src = pkgs.fishPlugins.colored-man-pages; }
      { name = "z";                   src = pkgs.fishPlugins.z; }
      { name = "forgit";              src = pkgs.fishPlugins.forgit; }
    ];

    interactiveShellInit = ''
     set -g fish_greeting ""

    if test -f ~/.cache/starship-active.toml
      set -gx STARSHIP_CONFIG ~/.cache/starship-active.toml
    else
      set -gx STARSHIP_CONFIG (realpath ~/.config/starship/tokyo-night.toml)
    end

    starship init fish | source
  '';

    functions = {
     starship-theme = ''
      set -l presets tokyo-night pastel-powerline gruvbox-rainbow jetpack pure-preset
       if test (count $argv) -eq 0
        echo "Presets disponíveis:"
        for p in $presets
          echo "  $p"
        end
       return
      end
      set -l src ~/.config/starship/$argv[1].toml
       if test -f $src
       #rm -f ~/.cache/starship-active.toml
        cp (realpath $src) ~/.cache/starship-active.toml
        set -gx STARSHIP_CONFIG ~/.cache/starship-active.toml
        echo "Tema '$argv[1]' aplicado."
       else
        echo "Preset '$argv[1]' não encontrado."
      end
    '';
   };
};

 programs.starship = {
    enable = true;
    enableZshIntegration = false;
 };

 programs.kitty = {
    enable = true;
    themeFile = "Homebrew";  # Constant Perceptual Luminosity,  Cyberpunk neon, ENCON,H-PUX, Homebrew,Neowave,Wez,
    settings = {
      shell           = "${pkgs.fish}/bin/fish";
      background_opacity = "0.92";  # transparência — 0.0 invisível, 1.0 opaco
      blur_radius     = 5;          # blur do fundo (funciona com alguns compositors)
    };
};
      
      
      home.stateVersion = "26.05";

}