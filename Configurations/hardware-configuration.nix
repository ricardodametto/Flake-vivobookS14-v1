{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/hardware/cpu/intel-npu.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "vmd" "nvme" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "intel_gna" "xe" "i915" "snd_sof_pci_intel_mtl" "rtw89" "btusb" ];
  boot.extraModulePackages = [ ];

  # --- COPIADO DO ORIGINAL (UUIDs REAIS) ---
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bf00382b-179c-4ad5-a1a3-7477af6bc054";
    fsType = "btrfs";
    options = [ "subvol=@" "noatime" "compress=zstd" ]; # Adicionei as otimizações
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C2C9-D98E";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a93e362b-8466-4fdd-bf26-cf56ce850f09";
    fsType = "btrfs";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.npu.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
