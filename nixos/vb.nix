{ config, pkgs, ... }:
let
  hostName = "nixos";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix

      # Include configuration
      (import ./config/default.nix {
        inherit config pkgs hostName;
      })
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  # Set hostname.
  networking = {
    inherit hostName;
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s3.useDHCP = true;

  # Enable sound.
  sound.enable = true;

  hardware.opengl.enable = true;
  services.xserver.videoDrivers = [
    "nouveau"
  ];
}
