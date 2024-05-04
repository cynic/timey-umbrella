{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = with pkgs.buildPackages; [
      nodejs_20 elmPackages.elm elmPackages.elm-format elixir erlang rebar3
      pgadmin4-desktopmode
      firefox python311Packages.selenium python311 python311Packages.pytest
    ];
}
