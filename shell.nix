let _pkgs = import <nixpkgs> { };
in { pkgs ? import (_pkgs.fetchFromGitHub {
  owner = "NixOS";
  repo = "nixpkgs-channels";
  #branch@date: nixpkgs-unstable@2021-01-25
  rev = "502845c3e31ef3de0e424f3fcb09217df2ce6df6";
  sha256 = "0fcqpsy6y7dgn0y0wgpa56gsg0b0p8avlpjrd79fp4mp9bl18nda";
}) { } }:

with pkgs;

mkShell {
  buildInputs = [
    git
    qemu
    qemu_kvm
  ];
}