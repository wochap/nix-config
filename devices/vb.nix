{ config, pkgs, ... }:
let
  hostName = "nixos";
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    # Include configuration
    ./config/default.nix
  ];

  config = {
    boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };

    networking = {
      hostName = hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.enp0s3.useDHCP = true;
    };

    sound.enable = true;

    hardware = {
      pulseaudio.enable = true;
      opengl.enable = true;
    };

    services.xserver = {
      videoDrivers = [
        "nv"
        "nvidia"
        "nouveau"
      ];

      # Configure keymap in X11
      layout = "us";
      xkbOptions = "eurosign:e";
    };
  };
}
