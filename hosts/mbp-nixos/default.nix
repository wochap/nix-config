{ config, pkgs, lib, inputs, ... }:

let
  hostName = "gmbp";
  isHidpi = true;
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  draculaTheme = import ../../config/mixins/dracula.nix;
in {
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc-laptop-acpi_call
    inputs.nixos-hardware.nixosModules.apple-macbook-pro-11-5
    # inputs.nixos-hardware.nixosModules.common-gpu-amd-southern-islands
    ./hardware-configuration.nix
    ../../config/mixins/intel.nix
    ../../config/mixins/powerManagement.nix
    ../../config/mixins/temp-sensor.nix
    ../../config/mixins/backlight
    ../../config/mixins/mbpfan
    ../../config/nixos.nix
    # ./xorg.nix
  ];

  config = {
    _userName = userName;
    _isHidpi = isHidpi;
    _homeDirectory = "/home/${userName}";
    _configDirectory = configDirectory;
    _theme = draculaTheme;

    _custom.flatpak.enable = true;
    _custom.waydroid.enable = false;
    _custom.efi.enable = true;
    _custom.amdCpu.enable = false;
    _custom.amdGpu.enable = false;
    _custom.amdGpu.enableSouthernIslands = false;

    _custom.bspwm.enable = false;
    _custom.lightdm.enable = false;
    _custom.startx.enable = false;
    _custom.xorgWm.enable = false;

    _custom.hyprland.enable = false;
    _custom.sway.enable = true;
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
    home-manager.users.${userName}.home.stateVersion = "21.11";

    boot = {
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

        "radeon.cik_support=0"
        "amdgpu.cik_support=0"
      ];

      kernelModules = [ "hid-apple" ];
    };

    environment = {
      systemPackages = with pkgs; [
        # change keyboard backlight level
        # NOTE: looks like xfce4-power-manager manages it
        kbdlight

        # requires installing rEFInd
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
      # TODO: refactor to module options
      cpuFreqGovernor = "performance";
      cpufreq.min = 800000;
      cpufreq.max = 4000000;
    };

  };
}
