{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default =
            let
              getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
              forEachDir = exec: ''
                for dir in */; do
                  (
                    cd "''${dir}"

                    ${exec}
                  )
                done
              '';

              script =
                name: runtimeInputs: text:
                pkgs.writeShellApplication {
                  inherit name runtimeInputs text;
                  bashOptions = [
                    "errexit"
                    "pipefail"
                  ];
                };
            in
            pkgs.mkShellNoCC {
              packages =
                with pkgs;
                [
                  (script "build" [ ] ''
                    ${getSystem}

                    ${forEachDir ''
                      echo "building ''${dir}"
                      nix build ".#devShells.''${SYSTEM}.default"
                    ''}
                  '')
                  (script "check" [ nixfmt ] (forEachDir ''
                    echo "checking ''${dir}"
                    nix flake check --all-systems --no-build
                  ''))
                  (script "format" [ nixfmt ] ''
                    git ls-files '*.nix' | xargs nix fmt
                  '')
                  (script "check-formatting" [ nixfmt ] ''
                    git ls-files '*.nix' | xargs nixfmt --check
                  '')
                ]
                ++ [ self.formatter.${system} ];
            };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    }

    //

      {
        templates = rec {
          default = empty;

          empty = {
            path = ./empty;
            description = "Empty development environemnt for customisation";
          };

          python = {
            path = ./python;
            description = "Python development environment";
          };

          ruby = {
            path = ./ruby;
            description = "Ruby development environment";
          };

          tofu = {
            path = ./tofu;
            description = "Tofu development environment";
          };

          # Aliases
          terraform = tofu;
        };
      };
}
