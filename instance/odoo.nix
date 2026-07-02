{ lib, pkgs, ... }:
let
  waxPath = "/opt/wax";

  # A script to pull in all the database and filestore data from the production container
  pullProdDataScript = pkgs.writers.writeBashBin "pull-prod-data" import ../scripts/pull-prod-data.nix { pkgs=pkgs; ribbon="dev"; };
in {
  imports = [
    ./base.nix
  ];

  environment = {
    # Some parameters can be set in /etc/wax/ files to configure the container for a specific customer
    etc = {
      "wax/repo".text = lib.mkDefault ''
        Put url here
      '';
      "wax/branch".text = lib.mkDefault ''
        production-build
      '';
      "wax/production".text = lib.mkDefault ''
        10.2.3.4
      '';
    };

    systemPackages = [ pullProdDataScript ];    
  };

  # Set up the Wax build on first nixos rebuild
  system.userActivationScripts.waxSetup = {
    text = ''
      WAX_BRANCH=$(cat /etc/wax/branch | head -n 1)
      WAX_REPO=$(cat /etc/wax/repo | head -n 1)

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
