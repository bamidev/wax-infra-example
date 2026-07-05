{ hostName, lib, pkgs, ... }:
let
  openSshPort = 27022;
in {
  imports = lib.optionals (hostName == "pod") [
    ../hardware-configuration.nix
    ../qemu.nix
    ../bootloader.nix
  ];

  environment.systemPackages = with pkgs; [
    lsof
    nano
    psmisc
    screen
  ];

  networking = {
    firewall.allowedTCPPorts = [ openSshPort ];

    hostName = hostName;

    nftables.enable = true;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 90d";
    };

    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Have some useful programs available on each container, like Neovim, direnv...
  programs = {
    bash = {
      enable = true;

      #shellInit = ''
      #  eval $(direnv hook bash)
      #'';
    };

    direnv.enable = true;

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  security.sudo = {
    enable = true;
    extraRules = [
      # Admins don't need to provide a password to sudo, as they can only authenticate with an SSH key.
      { groups = [ "wheel" ]; commands = [
        { command = "ALL"; options = [ "NOPASSWD" ]; }
      ]; }
    ];
  };

  services = {
    # Enable OpenSSH on each container
    openssh = {
      enable = true;

      ports = [ openSshPort ];

      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "yes";
      };
    };

    rsync.enable = true;
  };

  system.stateVersion = "26.05";

  users = {
    mutableUsers = true;

    # Add an admin user to all containers
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
