{ config, pkgs, pkgs-unstable, ... }:

{
  # ============================================================
  # Ollama - Motor de Inteligência Artificial
  # ============================================================
  services.ollama = {
    enable = true;
    
    # Endereço de escuta da API
    host = "127.0.0.1";
    port = 11434;
    
    # Força a versão com suporte a aceleração via Vulkan
    package = pkgs-unstable.ollama-vulkan;
    
    environmentVariables = {
      OLLAMA_IGPU_ENABLE = "1";
    };
  };

  # ============================================================
  # Open WebUI - Interface Gráfica Local
  # ============================================================
  services.open-webui = {
    enable = true;
    port = 8080; # A interface ficará disponível em http://localhost:8080
    
    package = pkgs-unstable.open-webui;

    # Variáveis de ambiente para configuração do serviço
    environment = {
      # Aponta para o daemon local do Ollama que já está a rodar
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      
      # Desativa a necessidade de criar conta/login
      WEBUI_AUTH = "False"; 
    };
  };
}