{ ... }:
let
  openSshPort = 27022;
in {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.firewall.allowedTCPPorts = [ openSshPort ];

  # Enable OpenSSH on each container
  services = {
    openssh = {
      enable = true;

      ports = [ openSshPort ];

      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  system.stateVersion = "26.05";

  users = {
    mutableUsers = false;

    users.admin = {
      description = "Admin";
      isNormalUser = true;
      extraGroups = [ "wheel" ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4gv0OF52jorRoiylqIcsgZRtYp1aRmR9FQD7AwTt6Q bamidev@pm.me"
      ];
    };
  };
}
