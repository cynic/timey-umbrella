{
  description = "Dependencies for Timey";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell
          { packages = with pkgs;
              [ nodejs_20
                elmPackages.elm elmPackages.elm-format
                elixir erlang rebar3
                pgadmin4-desktopmode
                firefox nodePackages.mocha
                valkey
              ];
          };
      }
    );
}
