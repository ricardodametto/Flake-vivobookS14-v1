{ config, pkgs, pkgs-unstable, ... }:
{

# Configuração do runner para o GitHub Actions, para usar a pipeline de CI/CD com runners auto-hospedados.
  services.github-runners.scan-power = {
    enable = true;
    url = "https://github.com/ricardodametto/scan-power";
    tokenFile = "/var/lib/github-runner/scan-power.token";
    user = "github-runner";
    name = "nixos-docker-runner";
    extraLabels = [ "self-hosted" "linux" "nixos" ];

  extraPackages = with pkgs-unstable; [
    docker
    git
    coreutils
  ];
  
  extraEnvironment = {
    DOCKER_HOST = "unix:///var/run/docker.sock";
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1";
  };

  # CORREÇÃO CRUCIAL: Abre o sandbox do systemd para o .NET enxergar o cgroup e o Docker
  serviceOverrides = {
    ProtectSubdirectories = false;
    ProtectProc = "default";
    ProcSubset = "all";
    PrivateDevices = false;
    RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
  };
};  
  
users.users.github-runner = {
  extraGroups = [ "docker" ];
  isSystemUser = true;        # o módulo cria como system user
  group = "github-runner";    # grupo primário criado pelo módulo
};

users.groups.github-runner = {};
}