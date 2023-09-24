{ config, pkgs, lib, inputs, ... }:

let
  hostName = "gmbp";
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  catppuccinMochaTheme = import ../../config/mixins/catppuccin-mocha.nix;
in {
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc-laptop-acpi_call
    inputs.nixos-hardware.nixosModules.apple-macbook-pro-11-5
    inputs.nixos-hardware.nixosModules.common-gpu-amd-southern-islands
    ./hardware-configuration.nix
    ./intel.nix
    ../../config/nixos.nix
  ];

  config = {
    # NOTE: amdvlk gives errors?
    hardware.amdgpu.amdvlk = false;
    hardware.amdgpu.loadInInitrd = true;

    _userName = userName;
    _homeDirectory = "/home/${userName}";
    _configDirectory = configDirectory;
    _custom.globals.themeColors = catppuccinMochaTheme;
    _custom.globals.isHidpi = true;

    _custom.tui.nixDirenv.enable = true;

    _custom.gui.qutebrowser.enable = true;

    _custom.wm.email.enable = true;
    _custom.wm.calendar.enable = true;
    _custom.wm.networking.enable = true;
    _custom.wm.powerManagement.enable = true;
    _custom.wm.backlight.enable = true;
    _custom.wm.audio.enable = true;
    _custom.wm.cursor.enable = true;
    _custom.wm.xdg.enable = true;
    _custom.wm.dbus.enable = true;
    _custom.wm.bluetooth.enable = true;
    _custom.wm.qt.enable = true;
    _custom.wm.gtk.enable = true;

    _custom.nix-alien.enable = true;
    _custom.interception-tools.enable = true;
    _custom.android.enable = true;
    _custom.android.sdk.enable = false;
    _custom.steam.enable = true;
    _custom.mbpfan.enable = true;
    _custom.docker.enable = true;
    _custom.mongodb.enable = true;
    _custom.virt.enable = true;
    _custom.flatpak.enable = true;
    _custom.waydroid.enable = false;

    _custom.hardware.efi.enable = true;
    _custom.hardware.amdCpu.enable = false;
    _custom.hardware.amdGpu.enable = false;
    _custom.hardware.amdGpu.enableSouthernIslands = false;

    _custom.dwl.enable = true;
    # _custom.river.enable = true;
    # _custom.hyprland.enable = true;
    # _custom.sway.enable = true;
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
    # changes in each release.
    home-manager.users.${userName} = {
      home.stateVersion = "21.11";

      _custom.programs.waybar.settings.mainBar = {
        temperature = { thermal-zone = 2; };
        keyboard-state = { device-path = "/dev/input/event23"; };
      };
    };

    boot = {
      # kernel 5.15.119 works with amdgpu driver
      kernelPackages = pkgs.prevstable-kernel-pkgs.linuxPackages;

      kernelParams = [
        # needed for suspend
        "acpi_osi=Darwin"

        # needed function keys
        "hid_apple.fnmode=2"
        "hid_apple.swap_opt_cmd=1"

        # chatgpt suggestions, power optimizations
        "i915.enable_guc=3"
        "i915.enable_fbc=1"
        "i915.enable_psr=1"
        "radeon.dpm=1"
        "radeon.runpm=1"
      ];

      kernelModules = [ "hid-apple" ];
    };

    environment = {
      systemPackages = with pkgs;
        [
          # NOTE: requires installing rEFInd
          # more info on https://github.com/0xbb/gpu-switch
          gpu-switch
        ];
    };

    networking = {
      inherit hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.wlp4s0.useDHCP = true;
    };

    services = {
      xserver = {

        # Setup keyboard
        layout = "us";
        xkbModel = "pc104";
        xkbVariant = "";

        # Enable touchpad support (enabled default in most desktopManager).
        libinput.enable = true;
        libinput.touchpad.naturalScrolling = true;
        libinput.touchpad.tapping = false;
      };
    };

    # Enable webcam
    hardware.facetimehd.enable = true;

    # Default cpu cpuFreqGovernor at startup
    powerManagement = {
      cpuFreqGovernor = "performance";
      cpufreq.min = 800000;
      cpufreq.max = 4000000;
    };

    # setup video drivers
    services.xserver = {
      videoDrivers = [ "modesetting" "amdgpu" "radeon" "intel" ];

      deviceSection = ''
        Option "EnablePageFlip" "off"
        Option "TearFree" "false"
        Option "DRI" "3"
      '';
    };
  };
}
