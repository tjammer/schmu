{
  description = "schmu development environment for Zero to Nix";

  # Flake inputs
  inputs = { nixpkgs.url = "nixpkgs"; };

  # Flake outputs
  outputs = { self, nixpkgs }:
    let
      # Systems supported
      allSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Helper to provide system-specific attributes
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f:
        builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
      forAllSystems = f:
        genAttrs allSystems
        (system: f { pkgs = import nixpkgs { inherit system; }; });
    in {
      # Development environment output
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          # The Nix packages provided in the environment
          packages = with pkgs; [
            gcc
            pkg-config
            llvmPackages_13.libllvm
            cmake
            python38
            hyperfine
            tokei
            valgrind
            gdb
          ];
        };
      });
    };
}
