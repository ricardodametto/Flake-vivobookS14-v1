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

     
     ../Extra-Packages/winbox.nix
     ../Extra-Packages/nvim.nix

     ../Firewall-Rules/firewall-rules.nix

     ../User/user.nix
     ../Deploy/runner-self.nix
     ../Garbage-Collector/garbage.nix

     # Gnome-Environment
     ../Gnome-Environment/gnome-essentials.nix
     ../Gnome-Environment/gnome-extensions.nix
     ../Gnome-Environment/pnetlab.nix
     ../Gnome-Environment/apps.nix
     ../Gnome-Environment/system-tools.nix
     ../Gnome-Environment/development.nix

     ../Extra-Packages/ollama.nix
  ];
}