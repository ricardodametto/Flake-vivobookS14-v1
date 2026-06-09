# Host entrypoint: ASUS Vivobook S 14 S3407CA (Arrow Lake-H)
{ config, pkgs, lib, pkgs-unstable, nvf, ... }:
{
  imports = [
     ./hardware-configuration.nix
    
     ../Bootloader/bootloader.nix
     
     ../Kernel-space/kernel-details.nix
     ../Kernel-space/libvirt-details.nix
     ../Kernel-space/container.nix 
     ../Kernel-space/kvm-details.nix

      ../Gnome-Environment/gnome-system.nix
     
      ../Extra-Packages/winbox.nix
      ../Extra-Packages/nvim.nix

      ../Firewall-Rules/firewall-rules.nix

      ../User/user.nix
      ../Deploy/runner-self.nix
      ../Garbage-Collector/garbage.nix

      # Gnome-Environment
      ../gnome-essentials.nix
      ../gnome-extensions.nix
      ../pnetlab.nix
      ../apps.nix
      ../system-tools.nix
      ../development.nix
      


    


  ];
}