{ pkgs, ... }:
{
  services = {
    patroni = {
      enable = true;
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
