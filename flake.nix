{
  description = "SourceGit Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... } @inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      sourcegit = pkgs.callPackage ./default.nix { };
    in
    {
      packages."${system}" = {
        sourcegit = sourcegit;
        default = sourcegit;
      };
    };
}
