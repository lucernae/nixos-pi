{ config, pkgs, lib, ... }:
{

  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>

    # For nixpkgs cache
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  sdImage.compressImage = true;
  

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
 
  # !!! Set to specific linux kernel version
  boot.kernelPackages = pkgs.linuxPackages_5_4;

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  boot.kernelParams = ["cma=256M"];

  # Settings above are the bare minimum
  # All settings below are customized depending on your needs

  # systemPackages
  environment.systemPackages = with pkgs; [ 
    vim curl wget nano bind kubectl helm iptables openvpn
    python3 nodejs-12_x docker-compose ];

  services.openssh = {
      enable = true;
      permitRootLogin = "yes";
  };

  programs.zsh = {
      enable = true;
      ohMyZsh = {
          enable = true;
          theme = "bira";
      };
  };


  virtualisation.docker.enable = true;

  networking.firewall.enable = false;

  # WiFi
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };

  # put your own configuration here, for example ssh keys:
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = true;
  users.groups = {
    nixos = {
      gid = 1000;
      name = "nixos";
    };
  };
  users.users = {
    nixos = {
      uid = 1000;
      home = "/home/nixos";
      name = "nixos";
      group = "nixos";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" ];
    };
  };
  users.extraUsers.root.openssh.authorizedKeys.keys = [
      # Your ssh key
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDqlXJv/noNPmZMIfjJguRX3O+Z39xeoKhjoIBEyfeqgKGh9JOv7IDBWlNnd3rHVnVPzB9emiiEoAJpkJUnWNBidL6vPYn13r6Zrt/2WLT6TiUFU026ANdqMjIMEZrmlTsfzFT+OzpBqtByYOGGe19qD3x/29nbszPODVF2giwbZNIMo2x7Ww96U4agb2aSAwo/oQa4jQsnOpYRMyJQqCUhvX8LzvE9vFquLlrSyd8khUsEVV/CytmdKwUUSqmlo/Mn7ge/S12rqMwmLvWFMd08Rg9NHvRCeOjgKB4EI6bVwF8D6tNFnbsGVzTHl7Cosnn75U11CXfQ6+8MPq3cekYr lucernae@lombardia-N43SM"
  ];
}
