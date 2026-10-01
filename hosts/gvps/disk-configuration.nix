{ inputs, lib, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ];

  config = {
    # OVH VPS boots SeaBIOS: hybrid BIOS+EFI grub, disko fills grub.devices
    boot.loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        device = lib.mkForce "";
        efiSupport = true;
        efiInstallAsRemovable = true;
        useOSProber = lib.mkForce false;
      };
    };

    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/sda"; # Ensure this matches your lsblk output
          content = {
            type = "gpt";
            partitions = {
              bios = {
                size = "1M";
                type = "EF02";
              };
              boot = {
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
