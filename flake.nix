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
        lib = nixpkgs.lib;

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
          incus launch base $1-$2
          incus file delete -f $1-$2/etc/nixos
          incus file push -r /etc/nixos $1-$2/etc/
          sleep 1
          incus exec $1-$2 -- chown -R admin:root /etc/nixos
          incus exec $1-$2 -- sudo -u admin nixos-rebuild switch --flake /etc/nixos#$2

          IP4_ADDRESS=$(incus list $1-$2 --format json | ${lib.getExe pkgs.jq}  -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
          # Pin the IPv4 address so that we can use it to configure the containers to find eachother
          incus config device set $1-$2 eth0 ipv4.address $IP4_ADDRESS
          echo $IP4_ADDRESS
        '';
        createSimpleGroup = pkgs.writers.writeBashBin "create-simple-group" ''
          set -ex
          $DB_ADDRESS=$(${createContainer}/bin/create-container $1 database)
          
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

        database = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "database";
          };
          modules = [ ./instance/database.nix ];
        };

        database-standby = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostName = "database-standby";
          };
          modules = [ ./instance/database.nix ];
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
