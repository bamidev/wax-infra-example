{
  description = "Your flake description...";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        generateScript = pkgs.writers.writeBashBin "generate-image" (with pkgs; ''
          set -x
          ${nixos-generators}/bin/nixos-generate -f lxc --flake .#odooInstance
          ${nixos-generators}/bin/nixos-generate -f lxc-metadata --flake .#odooInstance
        '');
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            generateScript
          ];
        };
      }
    ) // {
      nixosConfigurations = {
        odooInstance = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./instance/odoo.nix ];
        };

        pod = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./instance/pod.nix ];
        };
      };
    };
}
