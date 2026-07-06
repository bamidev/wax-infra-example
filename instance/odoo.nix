{ lib, pkgs, isProd, ... }:
let
  waxPath = "/opt/wax";

  # A script to pull in all the database and filestore data from the production container
  pullProdDataScript = pkgs.writers.writeBashBin "pull-prod-data" import ../scripts/pull-prod-data.nix { pkgs=pkgs; ribbon="dev"; };
in {
  imports = [
    ./base.nix
  ];

  boot.isContainer = true;

  environment = {
    # Some parameters can be set in /etc/wax/ files to configure the container for a specific tenant
    etc = {
      "wax/env".text = lib.mkDefault ''
        WAX_BRANCH="production-build"
        WAX_HOSTNAME="example.com"
        WAX_PRODUCTION_CONTAINER="10.1.2.3"
        WAX_REPO="git@github.com:xxx/abc.git"
      '';
    };

    systemPackages = lib.optionals (!isProd) [ pullProdDataScript ];    
  };

  # Set up the Wax build on first nixos rebuild
  system.userActivationScripts.waxSetup = {
    text = ''
      source /etc/wax/env

      if [ ! -d "${waxPath}" ]; then
        ${pkgs.git}/bin/git clone -b "$WAX_BRANCH" "$WAX_REPO" "${waxPath}"
      fi
    '';
  };

  # A systemd unit for the Wax build, to keep it running
  systemd.services.wax = {
    description = "Wax service";

    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "exec";

      ExecStart = waxPath;
      User = "wax";
      Group = "wax";
      Restart = "on-failure";
      RestartSec = 5;

      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  # Odoo will run from a dedicated system user.
  users = {
    extraUsers = {
      wax = {
        createHome = true;
        description = "Odoo process user";
        home = waxPath;
        group = "wax";
        isSystemUser = true;
      };
    };

    groups.wax = {};
  };
}
