{ config, pkgs, lib, inputs, ... }:

let
  hostName = "gmbp";
  # Common values are 96, 120 (25% higher), 144 (50% higher), 168 (75% higher), 192 (100% higher)
  isHidpi = true;
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  draculaTheme = import ../../config/mixins/dracula.nix;
in {
  imports = [
    "${inputs.nixos-hardware}/common/pc/laptop/acpi_call.nix"
    ./mpb-hardware.nix
    ./hardware-configuration.nix
    ../../config/mixins/intel.nix
    ../../config/mixins/powerManagement.nix
    ../../config/mixins/backlight.nix
    ../../config/mixins/mbpfan
    ../../config/nixos.nix
    ./xorg.nix
  ];

  config = {
    _userName = userName;
    _isHidpi = isHidpi;
    _homeDirectory = "/home/${userName}";
    _configDirectory = configDirectory;
    _theme = draculaTheme;

    _custom.amdCpu.enable = true;
    _custom.amdGpu.enable = true;
    _custom.amdGpu.enableSouthernIslands = true;
    _custom.bspwm.enable = true;
    _custom.lightdm.enable = false;
    _custom.startx.enable = true;
    _custom.xorgWm.enable = true;

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

      kernelParams = [
        # needed for suspend
        "acpi_osi=Darwin"

        # needed function keys
        "hid_apple.fnmode=2"
        "hid_apple.swap_opt_cmd=1"
      ];

      kernelModules = [ "hid-apple" ];
    };

    environment = {
      sessionVariables = {
        WIFI_DEVICE = "wlp4s0";
        MODULES_RIGHT =
          "recording dunst mbpfan backlight battery volume wifi date";
      };

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
      hostName = hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.wlp4s0.useDHCP = true;
    };

    hardware = { video.hidpi.enable = true; };

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
      # cpufreq.max = 3000000;
    };

  };
}
