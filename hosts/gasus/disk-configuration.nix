{ config, inputs, lib, pkgs, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ];

  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/sda"; # Ensure this matches your lsblk output
          content = {
            type = "gpt";
            partitions = {
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
