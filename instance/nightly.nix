{ pkgs, ... }:
let
  pullProdDataScript = pkgs.writers.writeBashBin "pull-prod-data" import ../scripts/pull-prod-data.nix { pkgs=pkgs; ribbon="dev"; };
in {
  imports = [ ./odoo.nix ];

  services = {
    cron = {
      enable = true;
      systemCronJobs = [
        "0 2 * * *  root  ${pullProdDataScript}/bin/pull-prod-data / >> /var/log/cron/sync-with-prod.log 2>&1"
      ];
    };

    # Add logrotate configuration for the log of the nightly cron job
    logrotate = {
      enable = true;

      settings = {
        "/var/log/cron/sync-with-prod.log" = {
          frequency = "daily";
          rotate = 3;
        };
      };
    };
  };
}
