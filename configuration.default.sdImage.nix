{ config, pkgs, lib, ... }:
{

  imports = [
    <nixos/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix>

    # For nixpkgs cache
    <nixos/nixos/modules/installer/cd-dvd/channel.nix>

    # main configuration
    ./configuration.default.nix
  ];

  sdImage.compressImage = true;

  system.copySystemConfiguration = true;
}
