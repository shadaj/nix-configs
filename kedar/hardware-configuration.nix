# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "tank/root/nixos";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "tank/root/home";
      fsType = "zfs";
    };

  fileSystems."/tank/minecraft" =
    { device = "tank/root/minecraft";
      fsType = "zfs";
    };

  fileSystems."/tank/games" =
    { device = "tank/root/games";
      fsType = "zfs";
    };

  fileSystems."/var/lib/docker" =
    { device = "tank/docker";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-CT1000P5SSD8_20502BEE72A8-part3";
      fsType = "vfat";
    };

  fileSystems."/swamp" =
    { device = "swamp";
      fsType = "zfs";
    };

  fileSystems."/swamp/media" =
    { device = "swamp/media";
      fsType = "zfs";
    };

  fileSystems."/swamp/time-machine" =
    { device = "swamp/time-machine";
      fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
