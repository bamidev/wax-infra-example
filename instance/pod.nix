{ fsDriver, ... }:
{
  imports = [
    ./base.nix
  ];

  # VM provisioning fix, needed by BlackHOST KVM hypervisor during creation
  # can be removed, however will result in losing the ability for VM password reset & network reconfiguring
  environment.etc = {
    fstab.mode = "0644";
    hosts.mode = "0644";
    os-release.mode = "0644";
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
