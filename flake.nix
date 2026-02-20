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

            validate-branch-commits = {
              enable = true;
              name = "validate-branch-commits";
              entry = "${pkgs.writeShellScript "validate-branch-commits" ''
                if [ -n "''${IN_NIX_SHELL:-}" ] || [ -z "''${NIX_BUILD_TOP:-}" ]; then
                  set -euo pipefail
                  BASE_BRANCH="''${BASE_BRANCH:-main}"
                  COMMITS=$(git log --format="%H" "origin/$BASE_BRANCH..HEAD" 2>/dev/null || git log --format="%H" HEAD)
                  [ -z "$COMMITS" ] && exit 0
                  FAILED=0
                  while IFS= read -r commit; do
                    MSG=$(git log --format=%B -n 1 "$commit")
                    if ! echo "$MSG" | ${pkgs.convco}/bin/convco check --from-stdin >/dev/null 2>&1; then
                      echo "Invalid commit message in $commit:"
                      echo "$MSG"
                      FAILED=1
                    fi
                  done <<<"$COMMITS"
                  [ $FAILED -eq 1 ] && exit 1 || exit 0
                else
                  exit 0
                fi
              ''}";
              pass_filenames = false;
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
