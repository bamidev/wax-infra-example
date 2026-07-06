{ lib, ... }:
let
  config = if builtins.pathExist /etc/tenant-config.nix then
    import /etc/tenant-config.nix
  else
    {};
  configDefaults = {
    maxConnections = 60000;
    productionServers = [];
  };
  completeConfig = config // configDefaults;
in {
  imports = [
    ./base.nix
  ] ++ lib.optionals (builtins.pathExist /etc/tenant/config.nix) [
    /etc/tenant/config.nix
  ];

  boot.isContainer = true;

  services = {
    etcd.enable = true;

    haproxy = {
      enable = true;

      config = ''
        global
          maxconn ${completeConfig.maxConnections}
          log 127.0.0.1 local0
          chroot /var/lib/haproxy

        defaults
          mode http
          # This way the websocket connections gets distributed better
          balance leastconn

        frontend main
          bind :80
          bind :443 ssl crt /etc/ssl/certs/tenant.pem
          http-request redirect scheme https code 301 if !{ssl_fc}
          default_backend odoo_servers

        backend odoo_servers
        '' + (builtins.map (server: "  server o1 ${server}:8069 check\n") completeConfig.productionServers) + ''


      '';
    };
  };
}
