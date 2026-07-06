{ ... }:
{
  # Use the GRUB 2 boot loader.
  boot = {
    extraModulePackages = [];

    initrd = {
      availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" "sr_mod" ];
      kernelModules = [];
    };

    kernelModules = [ "kvm-amd" ];  

    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  fileSystems."/" = {
    device = "/dev/sda2";
    fsType = "ext4";
  };

  networking.useDHCP = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  swapDevices = [
    { device = "/dev/sda1"; }
  ];
}
