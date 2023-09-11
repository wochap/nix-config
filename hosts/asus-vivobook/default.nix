{ config, pkgs, lib, inputs, ... }:

let
  hostName = "vivobook";
  userName = "franshesca";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  catppuccinMochaTheme = import ../../config/mixins/catppuccin-mocha.nix;
in {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    ./hardware-configuration.nix
    ../../config/nixos.nix
  ];

  config = {
    _userName = userName;
    _homeDirectory = "/home/${userName}";
    _configDirectory = configDirectory;
    _custom.globals.themeColors = catppuccinMochaTheme;
    _custom.globals.isHidpi = false;

    _custom.tui.nixDirenv.enable = true;

    _custom.gui.qutebrowser.enable = false;

    _custom.wm.email.enable = false;
    _custom.wm.calendar.enable = false;
    _custom.wm.networking.enable = true;
    _custom.wm.powerManagement.enable = false;
    _custom.wm.backlight.enable = false;
    _custom.wm.audio.enable = false;
    _custom.wm.cursor.enable = false;
    _custom.wm.xdg.enable = false;
    _custom.wm.dbus.enable = false;
    _custom.wm.bluetooth.enable = false;
    _custom.wm.qt.enable = false;
    _custom.wm.gtk.enable = false;

    _custom.interception-tools.enable = false;
    _custom.steam.enable = true;
    _custom.mbpfan.enable = false;
    _custom.docker.enable = true;
    _custom.mongodb.enable = true;
    _custom.virt.enable = false;
    _custom.flatpak.enable = true;
    _custom.waydroid.enable = true;

    _custom.hardware.efi.enable = true;
    _custom.hardware.amdCpu.enable = true;
    _custom.hardware.amdGpu.enable = false;
    _custom.hardware.amdGpu.enableSouthernIslands = false;

    _custom.gnome.enable = true;
    _custom.dwl.enable = false;
    _custom.river.enable = false;
    _custom.hyprland.enable = false;
    _custom.sway.enable = false;
    _custom.waylandWm.enable = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home-manager.users.${userName}.home.stateVersion = "21.03";

    boot = {
      # kernelParams = [
      #   # needed function keys
      #   "hid_apple.fnmode=2"
      # ];
      # kernelModules = [ "hid-apple" ];
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    networking = {
      inherit hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.wlp1s0.useDHCP = true;
    };

    # Fix windows dualboot clock
    time.hardwareClockInLocalTime = true;

    services.xserver = {

      # Setup keyboard
      layout = "latam";
      xkbModel = "pc104";
      # xkbVariant = "altgr-intl";

      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;
      libinput.touchpad.naturalScrolling = true;
      libinput.touchpad.tapping = false;
    };
  };
}
