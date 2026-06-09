# ==============================================================================
# Extra-Packages/winbox.nix
#
# Derivation manual do WinBox 4 para Linux.
#
# Por que existe este arquivo:
#   O pacote disponível no nixpkgs está desatualizado. Esta derivation
#   busca diretamente do servidor oficial da MikroTik e aplica os patches
#   de biblioteca necessários via autoPatchelfHook para funcionar no NixOS.
#
#   Não foi submetida à comunidade — uso exclusivo neste flake.
#
# Atualização de versão:
#   1. Altere `version` para a nova versão
#   2. Atualize o `sha256` com:
#      nix-prefetch-url --unpack https://download.mikrotik.com/routeros/winbox/<versão>/WinBox_Linux.zip
# ==============================================================================

{ config, pkgs, lib, ... }:

let
  winbox = pkgs.stdenv.mkDerivation rec {
    pname   = "winbox";
    version = "4.1";

    src = pkgs.fetchzip {
      url    = "https://download.mikrotik.com/routeros/winbox/${version}/WinBox_Linux.zip";
      sha256 = "sha256-GmHfnN2gfEPI54RAI60rCGSFCSbolvGQ/csIfNL5Ceo=";
      stripRoot = false;
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook  # Patcha automaticamente os RPATH dos binários ELF
      makeWrapper       # Injeta LD_LIBRARY_PATH no wrapper do binário
      copyDesktopItems  # Copia o .desktop para o lugar correto
    ];

    # Dependências de runtime — autoPatchelfHook resolve os .so automaticamente
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      libx11
      libxcursor
      libxrandr
      libxinerama
      libxi
      libxext
      libxcb
      libxcb-cursor
      libxcb-wm
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxkbcommon
      fontconfig
      freetype
      libGL
      zlib
      dbus
    ];

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/winbox
      cp $src/WinBox $out/share/winbox/
      cp -r $src/assets $out/share/winbox/

      # Wrapper injeta as libs no LD_LIBRARY_PATH em tempo de execução
      makeWrapper $out/share/winbox/WinBox $out/bin/winbox \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}"
    '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name        = "winbox";
        exec        = "winbox";
        icon        = "winbox";
        desktopName = "WinBox 4";
        categories  = [ "Network" ];
      })
    ];

    meta = with pkgs.lib; {
      description = "WinBox — MikroTik RouterOS GUI (build manual, nixpkgs desatualizado)";
      homepage    = "https://mikrotik.com/download";
      license     = licenses.unfree;
      platforms   = [ "x86_64-linux" ];
    };
  };

in
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages  = [ winbox ];

  # Wrapper com capabilities de rede (desabilitado por enquanto)
  # Habilitar se o WinBox precisar de acesso Layer 2 sem root:
  # security.wrappers.winbox = {
  #   source       = "${winbox}/bin/winbox";
  #   capabilities = "cap_net_raw,cap_net_admin+ep";
  #   owner        = "ricardo";
  #   group        = "users";
  # };
}