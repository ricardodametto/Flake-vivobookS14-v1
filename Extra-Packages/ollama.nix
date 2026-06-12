{ config, pkgs, pkgs-unstable, ... }:

{
  # Habilita o daemon do Ollama no nível do sistema
  services.ollama = {
    enable = true;
    
    # Opcional: Endereço de escuta da API.
    # 127.0.0.1 é seguro para uso local. Mude para "0.0.0.0" 
    # apenas se for acessar o Ollama a partir de outro computador na rede.
    host = "127.0.0.1";
    port = 11434;
    package = pkgs-unstable.ollama-vulkan;
    environmentVariables = {
      OLLAMA_IGPU_ENABLE = "1";
    };
  };
}