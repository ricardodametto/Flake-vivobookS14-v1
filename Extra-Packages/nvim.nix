# ==============================================================================
# Extra-Packages/nvim.nix
#
# Neovim via NVF (NotAShelf's Neovim Flake).
#
# Por que NVF e não um pacote simples:
#   O NVF é declarado como módulo NixOS (nvf.nixosModules.default importado
#   no flake.nix). Isso permite configurar LSP, Treesitter, temas e plugins
#   de forma totalmente declarativa — sem gerenciador de plugins externo.
#
# LSP habilitados:
#   • clangd     → C / C++
#   • jdtls      → Java
#   • gopls      → Go
#   • pyright    → Python
#   • nil / nixd → Nix
#
# Treesitter habilitado globalmente (enableTreesitter = true)
# Assembly: apenas Treesitter, sem LSP nativo disponível
# ==============================================================================

{ ... }:

{
  programs.nvf = {
    enable = true;

    settings.vim = {
      viAlias  = true;
      vimAlias = true;

      # ============================================================
      # LSP — base para todos os language modules
      # ============================================================
      lsp = {
        enable       = true;
        formatOnSave = true;
        trouble.enable = true;   # Lista de diagnósticos integrada
      };

      # Clipboard do sistema via unnamedplus (Wayland/X11)
      options = {
        clipboard = "unnamedplus";
      };

      # Autocomplete via nvim-cmp (integra automaticamente com LSP)
      autocomplete.nvim-cmp.enable = true;

      # Auto pairs de parênteses, chaves e colchetes
      autopairs.nvim-autopairs.enable = true;

      # ============================================================
      # Linguagens
      # ============================================================
      languages = {
        enableTreesitter = true;

        # C / C++ — clangd + clang-format
        clang = {
          enable        = true;
          lsp.enable    = true;
          format.enable = true;
        };

        # Java — jdtls
        # Requer estrutura de projeto (pom.xml ou build.gradle) para funcionar
        java = {
          enable     = true;
          lsp.enable = true;
        };

        # Assembly — apenas Treesitter (sem LSP nativo)
        assembly.enable = true;

        # Go — gopls + gofmt
        go = {
          enable        = true;
          lsp.enable    = true;
          format.enable = true;
        };

        # Python — pyright + black/ruff
        python = {
          enable        = true;
          lsp.enable    = true;
          format.enable = true;
        };

        # Nix — nil/nixd + nixpkgs-fmt
        nix = {
          enable        = true;
          lsp.enable    = true;
          format.enable = true;
        };
      };

      # ============================================================
      # Tema — Tokyo Night
      # ============================================================
      theme = {
        enable = true;
        name   = "tokyonight";
        style  = "night";
      };
    };
  };
}