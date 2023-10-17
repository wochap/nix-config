{ config, pkgs, lib, ... }:

let
  hostName = "gdesktop";
  isHidpi = false;
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  catppuccinMochaTheme = import ../../config/mixins/catppuccin-mocha.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../config/nixos.nix
    ../../config/mixins/temp-sensor.nix
  ];

  config = {
    _userName = userName;
    _homeDirectory = "/home/${userName}";
    _configDirectory = configDirectory;
    _custom.globals.themeColors = catppuccinMochaTheme;
    _custom.globals.isHidpi = false;

    _custom.tui.fontpreview-kik.enable = true;
    _custom.tui.lynx.enable = true;
    _custom.tui.wtf.enable = true;
    _custom.tui.nixDirenv.enable = true;

    _custom.gui.qutebrowser.enable = true;

    _custom.wm.email.enable = true;
    _custom.wm.calendar.enable = true;
    _custom.wm.networking.enable = true;
    _custom.wm.powerManagement.enable = true;
    _custom.wm.backlight.enable = false;
    _custom.wm.audio.enable = true;
    _custom.wm.cursor.enable = true;
    _custom.wm.xdg.enable = true;
    _custom.wm.dbus.enable = true;
    _custom.wm.bluetooth.enable = true;
    _custom.wm.qt.enable = true;
    _custom.wm.gtk.enable = true;

    _custom.neovim.enable = true;
    _custom.nix-alien.enable = true;
    _custom.interception-tools.enable = true;
    _custom.android.enable = true;
    _custom.android.sdk.enable = false;
    _custom.steam.enable = true;
    _custom.mbpfan.enable = false;
    _custom.docker.enable = true;
    _custom.mongodb.enable = true;
    _custom.virt.enable = true;
    _custom.flatpak.enable = true;
    _custom.waydroid.enable = false;

    _custom.hardware.efi.enable = true;
    _custom.hardware.amdCpu.enable = true;
    _custom.hardware.amdGpu.enable = true;
    _custom.hardware.amdGpu.enableSouthernIslands = false;

    _custom.dwl.enable = true;
    # _custom.river.enable = true;
    # _custom.hyprland.enable = true;
    # _custom.sway.enable = true;

    # waylandWm enables: ags, dunst, rofi, swappy, swaync, swww, tofi, waybar, wob
    _custom.waylandWm.enable = true;

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

      _custom.programs.waybar.settings.mainBar."modules-right" = lib.mkForce [
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

      # _custom.programs.waybar.settings.mainBar = {
      #   temperature = {
      #     hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
      #     input-filename = "temp1_input";
      #   };
      #   keyboard-state = { device-path = "/dev/input/event25"; };
      # };
    };

    networking = {
      inherit hostName;

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
  };
}
