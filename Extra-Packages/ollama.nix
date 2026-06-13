{ config, pkgs, pkgs-unstable, ... }:

{
  # ============================================================
  # Ollama - Motor de Inteligência Artificial
  # ============================================================
  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;
    
    package = pkgs-unstable.ollama-vulkan;
    
    environmentVariables = {
      # --- Backend de inferência ---------------------------------------------
      # Liga o backend Vulkan do ggml/llama.cpp. Sem isto, o Ollama cai pra CPU
      # (3.5 tok/s no qwen3:4b vs ~19 tok/s na iGPU — medido).
      OLLAMA_VULKAN = "1";          # adiciona/força 0
      
      # Permite que o Ollama use GPU INTEGRADA. O ggml-vulkan, por padrão, filtra
      # GPUs sem VRAM dedicada (UMA); esta flag destrava a Arc Arrow Lake, que
      # usa RAM compartilhada como "device memory".
      OLLAMA_IGPU_ENABLE = "1";     # troca de "1" pra "0"
      
      # --- Resolução de bibliotecas (camada do ld.so / loader) ---------------
      # Onde o linker dinâmico acha libvulkan.so e as libs do Mesa no NixOS
      # (não existe /usr/lib aqui; tudo vem de hardware.graphics.enable).
      # Pode ser redundante se o pacote já tiver rpath correto, mas custa zero.
      LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";
      
      # --- Seleção de driver (camada do loader Vulkan / ICD) -----------------
      # Força o loader a usar SÓ o ICD do Intel (ANV). Evita que ele enumere e
      # escolha o lavapipe (Vulkan por software na CPU) — que rodaria "na GPU"
      # no log mas 100% na CPU na prática. Nome novo de VK_ICD_FILENAMES (deprecado)
      VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
    };
  };

  # Configurações de isolamento e permissão do Systemd
  systemd.services.ollama.serviceConfig = {
    SupplementaryGroups = [ "render" "video" ];
    PrivateDevices = false;
    ProtectSystem = "strict";
    ProtectHome = true;
    ReadWritePaths = [ "/var/lib/ollama" ];
  };

  # ============================================================
  # Open WebUI - Interface Gráfica Local
  # ============================================================
  services.open-webui = {
    enable = true;
    port = 8080;
    package = pkgs-unstable.open-webui;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "False"; 
    };
  };
}