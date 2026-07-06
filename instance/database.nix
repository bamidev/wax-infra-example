{ pkgs, ... }:
{
  services = {
    patroni = {
      enable = true;

      settings = {
        postgresql = {
          parameters = {
            max_connections = 100;
            max_wal_senders = 10;
            wal_level = "replica";
            wal_log_hints = "on";
          };

          use_slots = true;
        };
      };
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;

      authentication = ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';

      ensureDatabases = [ "odoo" ];

      ensureUsers = [
        {
          name = "odoo";
          ensureClauses = {
            login = true;
          };
        }
      ];
    };
  };
}
