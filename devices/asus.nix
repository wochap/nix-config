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
    boot = {
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;
    };

    networking = {
      hostName = hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.enp2s0f1.useDHCP = true;
      interfaces.wlp3s0.useDHCP = true;
    };

    hardware = {
      opengl.enable = true;
      opengl.driSupport = true;
      opengl.driSupport32Bit = true;

      # Dual gpu
      bumblebee = {
        enable = false;
        driver = "nvidia";
        pmMethod = "none";
        connectDisplay = true;
      };
    };

    services.xserver = {
      libinput.enable = true;

      # videoDrivers = [
      #   "nouveau"
      #   "nvidia"
      # ];

      # Configure keymap in X11
      layout = "us";
      xkbOptions = "eurosign:e";
    };
  };
}
