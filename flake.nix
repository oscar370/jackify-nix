{
  description = "Jackify (Wabbajack modlist installer) packaged for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        jackify = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.jackify;
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
