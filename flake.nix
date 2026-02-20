{
  description = "minnasoft/mana";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        beam = pkgs.beam.packages.erlang_28;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            beam.erlang
            beam.elixir
            pkgs.git
          ];

          shellHook = ''
            export MIX_HOME=$PWD/.mix
            export HEX_HOME=$PWD/.hex
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
            mkdir -p $MIX_HOME $HEX_HOME
          '';
        };
      });
}
