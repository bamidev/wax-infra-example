{ fsDriver, ... }:
{
  imports = [
    ./base.nix
  ];

  boot.kernel.sysctl = {
    # Recommended for Postgres
    #"vm.overcommit_memory" = 2;
  };

  environment = {
    etc = {
      # VM provisioning fix, needed by BlackHOST KVM hypervisor during creation
      # can be removed, however will result in losing the ability for VM password reset & network reconfiguring
      fstab.mode = "0644";
      hosts.mode = "0644";
      os-release.mode = "0644";
    };

    variables = {
      MALLOC_ARENA_MAX = 1;
      PG_MALLOC_ARENA_MAX = "";
    };
  };

  networking.firewall.trustedInterfaces = [ "incus-bridge" ];

  users.users.admin.extraGroups = [ "incus-admin" ];

  virtualisation.incus = {
    enable = true;

    preseed = {
      networks = [
        {
          name = "incus-bridge";
          type = "bridge";
          config = {
            "ipv4.address" = "auto";
            "ipv4.nat" = "true";
            "ipv6.address" = "auto";
          };
        }
      ];

      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incus-bridge";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              size = "35GiB";
              type = "disk";
            };
          };
        }
      ];
      
      storage_pools = [
        {
          name = "default";
          config = {
            source = "/var/lib/incus/storage-pools/default";
          };
          driver = fsDriver;
        }
      ];

      storage_volumes = [
        {
          name = "default";
          pool = "default";
        }
      ];
    };
  };
}
