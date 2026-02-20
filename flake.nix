{
  description = "minnasoft/mana";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      git-hooks,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        beam = pkgs.beam.packages.erlang_28;
        elixir = beam.elixir_1_19;

        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            convco.enable = true;
            nixfmt-rfc-style.enable = true;
            deadnix.enable = true;
            statix.enable = true;

            shellcheck = {
              enable = true;
              excludes = [ ".envrc" ];
            };

            mix-lint = {
              enable = true;
              name = "mix-lint";
              entry = "${pkgs.writeShellScript "mix-lint" ''
                if [ -n "''${IN_NIX_SHELL:-}" ] || [ -z "''${NIX_BUILD_TOP:-}" ]; then
                  cd "$(git rev-parse --show-toplevel)"
                  export MIX_HOME="''${MIX_HOME:-$PWD/.nix-mix}"
                  export HEX_HOME="''${HEX_HOME:-$PWD/.nix-hex}"
                  ${elixir}/bin/mix lint
                else
                  exit 0
                fi
              ''}";
              files = "\\.(ex|exs)$";
              pass_filenames = false;
            };

            mix-test = {
              enable = true;
              name = "mix-test";
              entry = "${pkgs.writeShellScript "mix-test" ''
                if [ -n "''${IN_NIX_SHELL:-}" ] || [ -z "''${NIX_BUILD_TOP:-}" ]; then
                  cd "$(git rev-parse --show-toplevel)"
                  export MIX_HOME="''${MIX_HOME:-$PWD/.nix-mix}"
                  export HEX_HOME="''${HEX_HOME:-$PWD/.nix-hex}"
                  ${elixir}/bin/mix test --color
                else
                  exit 0
                fi
              ''}";
              files = "\\.(ex|exs)$";
              pass_filenames = false;
            };
          };
        };
      in
      {
        checks.pre-commit = pre-commit-check;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            beam.erlang
            elixir
            pkgs.git
            pkgs.docker
            pkgs.docker-compose
            pkgs.pre-commit
            pkgs.convco
            pkgs.nixfmt
            pkgs.deadnix
            pkgs.statix
            pkgs.shellcheck
            pkgs.shfmt
          ];

          shellHook = ''
            export LANG=en_US.UTF-8
            export LC_ALL=en_US.UTF-8
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
            mkdir -p $MIX_HOME $HEX_HOME
            ${pre-commit-check.shellHook}
          '';
        };
      }
    );
}
