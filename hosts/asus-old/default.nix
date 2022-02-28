{ config, pkgs, ... }:
let
  hostName = "gasus";
  isHidpi = false;
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  draculaTheme = import ../../config/mixins/dracula.nix;
in {
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../../config/mixins/backlight.nix
    ../../config/xorg.nix
  ];

  config = {
    _userName = userName;
    _isHidpi = isHidpi;
    _configDirectory = configDirectory;
    _theme = draculaTheme;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.11"; # Did you read the comment?

    home-manager.users.${userName} = {
      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "21.03";
    };

    boot = {
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;
    };

    environment = { sessionVariables = { WIFI_DEVICE = "wlp3s0"; }; };

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
      # Dual gpu
      bumblebee = {
        enable = false;
        driver = "nvidia";
        pmMethod = "none";
        connectDisplay = true;
      };
    };

    services.xserver = {
      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      # layout = "latam";
      # xkbVariant = "altgr-intl";

      # videoDrivers = [
      #   "nouveau"
      #   "nvidia"
      # ];

      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;
      libinput.touchpad.naturalScrolling = true;
      libinput.touchpad.tapping = false;
    };
  };
}
