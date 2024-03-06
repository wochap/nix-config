{ config, pkgs, lib, ... }:

let
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  catppuccinMochaTheme = import ../../modules/mixins/catppuccin-mocha.nix;
in {
  imports = [ ./hardware-configuration.nix ];

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.themeColors = catppuccinMochaTheme;

    # TODO: enable modules

    networking = {
      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.enp11s0.useDHCP = true;
      interfaces.enp42s0.useDHCP = true;
      interfaces.wlp10s0.useDHCP = true;
    };

    # Fix windows dualboot clock
    time.hardwareClockInLocalTime = true;

    services.xserver = {

      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      # xkbVariant = "altgr-intl";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.11"; # Did you read the comment?

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    home-manager.users.${userName} = {
      home.stateVersion = "21.11";

      programs.waybar.settings.mainBar."modules-right" = lib.mkForce [
        "tray"
        "custom/recorder"
        "idle_inhibitor"
        "custom/notifications"
        "custom/offlinemsmtp"
        "temperature"
        "pulseaudio"
        "bluetooth"
        "network"
        "clock"
      ];

      # programs.waybar.settings.mainBar = {
      #   temperature = {
      #     hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
      #     input-filename = "temp1_input";
      #   };
      #   keyboard-state = { device-path = "/dev/input/event25"; };
      # };
    };
  };
}
