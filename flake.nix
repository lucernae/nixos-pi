{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    devshell.url = "github:numtide/devshell";
  };

  outputs = { self, nixpkgs, flake-utils, devshell, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      apps.devshell = self.outputs.devShell.${system}.flakeApp;
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      packages = {
        nixosConfigurations =
          let
            inherit (nixpkgs.lib) nixosSystem;
          in
          rec {
             # to build: nix build github:lucernae/nix-config#nixosConfigurations.raspberry-pi_3.config.system.build.sdImage
            raspberry-pi_3 = nixosSystem {
              system = "aarch64-linux";
              modules = [
                "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
                # replace this with your target configuration
                ./configuration.nix

                # extra config for sdImage generator
                {
                  sdImage.compressImage = false;
                }
              ];
            };
            raspberry-pi_3_default = nixosSystem {
              system = "aarch64-linux";
              modules = [
                "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
                # replace this with your target configuration
                ./configuration.default.nix

                # extra config for sdImage generator
                {
                  sdImage.compressImage = false;
                }
              ];
            };
          };
      };
      devShell =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ devshell.overlays.default ];
          };
        in
        pkgs.devshell.mkShell {
          name = "nixos-pi";
          commands = [
          ];
          packages = with pkgs; [
            git
            qemu
            qemu_kvm
          ];
        };
    });
}
