{ lib, ... }:
{
  boot = {
    extraModulePackages = [];

    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "ehci_pci" "uas" "usb_storage" "sd_mod" ];
      kernelModules = [ "kvm-amd" ];
    };

    kernelModules = [ "kvm-amd" ];  

    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  fileSystems = {
    "/" = {
      device = "hdd/root";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/E9C8-4216";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

  hardware = rec {
    cpu.amd.updateMicrocode = lib.mkDefault enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkForce true;
  };

  networking = {
    hostId = "b00d1234";
    useDHCP = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  swapDevices = [
    { device = "/dev/disk/by-uuid/bb1ecbd6-0eb5-455d-966b-b475411dc222"; }
  ];
}
