{
  description = "Sistema NixOS + Home Manager do Ricardo — ASUS Vivobook S 14";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Adicione esta linha abaixo para buscar os pacotes em tempo real:
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # adicionei o nvim como input, forma diferente de instalar!
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
  };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };  

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nvf,... }:
    let
      system = "x86_64-linux";
      username = "ricardo";

      # Helper para reduzir repetição se quiser adicionar mais hosts depois
      mkSystem = hostName: hostPath:
        nixpkgs.lib.nixosSystem {
          inherit system;
          
      # Passa o canal instável de forma limpa para TODOS os sub-módulos do sistema
      specialArgs = {
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true; # Essencial para o VS Code
        };
      };    
          
      modules = [
        hostPath
          # 1. CARREGUE O NVF AQUI PRIMEIRO (Na raiz do sistema)
          nvf.nixosModules.default
          # Integra o Home Manager como módulo do sistema
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            
            # 🆕 Passa os mesmos argumentos extras para dentro do Home Manager
              home-manager.extraSpecialArgs = {
                pkgs-unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
            
            home-manager.users.${username} = {
              imports = [
                ./Home-Manager/home.nix
              ];
            };
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        # 🆕 Novo host para o ASUS Vivobook S 14
        vivobooks14-v1 = mkSystem "vivobooks14-v1" ./Configurations/default.nix;

        # (Opcional) Mantém o host antigo se quiser reutilizar o mesmo flake
        # nixos = mkSystem "nixos" ./hosts/nixos/default.nix;
      };
    };
}
