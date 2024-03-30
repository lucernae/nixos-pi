{ config, pkgs, lib, ... }:
{

  imports = [
    <nixos/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix>

    # For nixpkgs cache
    <nixos/nixos/modules/installer/cd-dvd/channel.nix>

    # main configuration
    ./configuration.nix
  ];

  sdImage.compressImage = false;

  system.copySystemConfiguration = true;
}
