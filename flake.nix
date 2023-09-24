{
    description = "Development environment";

  inputs = {
      nixpkgs = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs.lib) optional;
        pkgs = import nixpkgs { inherit system; };

        nodejs  = pkgs.nodejs_20;
        yarn = pkgs.yarn;
        pnpm = pkgs.nodePackages.pnpm;
      in
      {
          devShell = pkgs.mkShell
          {
              buildInputs = [
              nodejs
              yarn
              pnpm
            ];
          };
      }
    );
}
