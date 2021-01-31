{ config, pkgs, ... }:
let
  hostName = "gdesktop";
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    # Include configuration
    ./config/default.nix
  ];

  config = {
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.cleanTmpDir = true;

    networking = {
      hostName = hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.enp40s0.useDHCP = true;
      interfaces.wlp39s0.useDHCP = true;
    };

    sound.enable = true;

    hardware = {
      pulseaudio.enable = true;
      opengl.enable = true;
      opengl.driSupport32Bit = true;
      # video.hidpi.enable = true;
    };

    services.xserver = {
      videoDrivers = [
        "nvidia"
        "nouveau"
      ];

      # Configure keymap in X11
      layout = "us";
      xkbOptions = "eurosign:e";
    };
  };
}
