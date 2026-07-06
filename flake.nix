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

        # This script generates a new image for containers, and loads it into incus
        regenerateImageScript = pkgs.writers.writeBashBin "regenerate-image" (with pkgs; ''
          set -ex
          ROOTFS_TARBALL=$(${nixos-generators}/bin/nixos-generate -f lxc --flake .#$1 --show-trace)
          METADATA_TARBALL=$(${nixos-generators}/bin/nixos-generate -f lxc-metadata --flake .#$1)
          incus image import "$METADATA_TARBALL" "$ROOTFS_TARBALL" --reuse --alias $1
        '');

        regenerateBaseScript = pkgs.writers.writeBashBin "regenerate-base" ''
          set -e
          ${regenerateImageScript}/bin/regenerate-image base
        '';
        createContainer = pkgs.writers.writeBashBin "create-container" ''
          set -ex
          incus launch base $1 $2
          incus exec $1-$2 -- nixos-rebuild switch --flake /etc/nixos#$2
        '';
        createSimpleGroup = pkgs.writers.writeBashBin "create-simple-group" ''
          set -ex
          incus launch base $1-rproxy
          incus exec $1-rproxy -- nixos-rebuild switch --flake /etc/nixos#rproxy
          incus launch base $1-prod
          incus exec $1-rproxy -- nixos-rebuild switch --flake /etc/nixos#odoo-prod
          incus launch base $1-nightly
          incus exec $1-rproxy -- nixos-rebuild switch --flake /etc/nixos#odoo-nightly
          incus launch base $1-test
          incus exec $1-rproxy -- nixos-rebuild switch --flake /etc/nixos#odoo-test
          incus launch base $1-database
          incus exec $1-rproxy -- nixos-rebuild switch --flake /etc/nixos#database
          incus launch base $1-db-standby
          incus exec $1-rproxy -- nixos-rebuild switch --flake /etc/nixos#db-standby
        '';
      in {
        # The dev shell provides some useful commands to help with managing containers.
        devShells.default = pkgs.mkShell {
          packages = [
            createContainer
            createSimpleGroup
            regenerateImageScript
            regenerateBaseScript
          ];
        };
      }
    ) // {
      nixosConfigurations = {
        base = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "base";
          };
          modules = [ ./instance/base.nix ];
        };


        odoo-prod = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "odoo-prod";
            isProd = true;
          };
          modules = [ ./instance/odoo.nix ];
        };
        
        odoo-nightly = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "odoo-nightly";
            isProd = true;
          };
          modules = [ ./instance/odoo-nightly.nix ];
        };

        odoo-test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "odoo-test";
            isProd = false;
          };
          modules = [ ./instance/odoo.nix ];
        };

        pod = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "pod";
            fsDriver = "dir";
          };
          modules = [ ./instance/pod.nix ];
        };

        pod-vps = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "pod";
            fsDriver = "dir";
          };
          modules = [
            ./device/vps.nix
            ./instance/pod.nix
          ];
        };

        pod-zfs = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "pod";
            fsDriver = "zfs";
          };
          modules = [ ./instance/pod.nix ];
        };

        rproxy = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "rproxy";
          };
          modules = [ ./instance/rproxy.nix ];
        };
      };
    };
}
