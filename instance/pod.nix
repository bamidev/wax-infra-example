{ ... }:
{
  virtualisation.incus = {
    enable = true;

    preseed = {
      networks = {
        name = "incus-my-bridge";
        type = "bridge";
        config = {
          "ipv4.address" = "auto";
          "ipv4.nat" = "true";
          "ipv6.address" = "auto";
        };
      };

      profiles = [
        {
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              size = "35GiB";
              type = "disk";
            };
          };
          name = "default";
        }
      ];
      
      storage_pools = [
        {
          config = {
            source = "/var/lib/incus/storage-pools/default";
          };
          driver = "zfs";
          name = "default";
        }
      ];

      storage_volumes = [
        {
          name = "my-vol";
          pool = "data";
        }
      ];
    };
  };
}
