{
  inputs,
  ...
}:

{
  imports = [ inputs.disko.nixosModules.disko ];

  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/nvme1n1"; # Ensure this matches your lsblk output
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
              swap = {
                size = "8G";
                content = {
                  type = "swap";
                  extraArgs = [
                    "-L"
                    "swap"
                  ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "container";
                  passwordFile = "${../../secrets-git-crypt/user-password.key}"; # Used for non-interactive install
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
  };
}
