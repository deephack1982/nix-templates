{
  description = "Tofu infrastructure development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # overlays = [ overlay ];
          config.allowUnfree = true;
        };

        dependencies = with pkgs; [
          opentofu
          go-task
          terragrunt
          graphviz
        ];

        hook = ''
          # This is where I'll add any additional auth needed
          echo "DevShell up!"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = dependencies;
          shellHook = hook;
        };
      }
    );
}
