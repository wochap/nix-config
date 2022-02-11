{ config, pkgs, lib, inputs, ... }:

let
  hostName = "gmbp";
  # Common values are 96, 120 (25% higher), 144 (50% higher), 168 (75% higher), 192 (100% higher)
  isHidpi = true;
  dpi = 192;
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  cpupower = config.boot.kernelPackages.cpupower;
  draculaTheme = import ../../config/mixins/dracula.nix;
in {
  imports = [
    "${inputs.nixos-hardware}/common/pc/laptop/acpi_call.nix"
    ./mpb-hw.nix
    /etc/nixos/hardware-configuration.nix
    ../../config/mixins/backlight.nix
    # ../../config/wayland-minimal.nix
    ../../config/xorg.nix
    ./xorg.nix
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
      initrd.kernelModules = [ "amdgpu" ];

      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;

      kernelParams = [
        # needed for powersave
        "intel_pstate=active"

        # needed for suspend
        "acpi_osi=Darwin"

        # needed function keys
        "hid_apple.fnmode=2"
        "hid_apple.swap_opt_cmd=1"
      ];

      kernelModules = [ "coretemp" "intel_pstate" "hid-apple" ];
    };

    environment = {
      sessionVariables = { WIFI_DEVICE = "wlp4s0"; };

      systemPackages = with pkgs; [
        radeontop # monitor system amd

        cpupower-gui
        cpupower

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
        dpi = lib.mkIf (isHidpi) dpi;

        # Setup keyboard
        layout = "us";
        xkbModel = "pc104";
        xkbVariant = "";

        # Enable touchpad support (enabled default in most desktopManager).
        libinput.enable = true;
        libinput.touchpad.naturalScrolling = true;
        libinput.touchpad.tapping = false;

        # GPU drivers
        videoDrivers = [ "intel" "amdgpu" ];

        deviceSection = ''
          # does it fix screen tearing? maybe...
          Option         "NoLogo" "1"
          Option         "RenderAccel" "1"
          Option         "TripleBuffer" "true"
          Option         "MigrationHeuristic" "greedy"
          Option         "AccelMethod" "sna"
          Option         "TearFree"    "true"
        '';
      };

      # Macbook fan config
      mbpfan = {
        enable = true;
        verbose = true;
        lowTemp = 30;
        highTemp = 50;
        maxTemp = 85;
        maxFanSpeed = 5500;
        minFanSpeed = 4500;
        # settings.general = {
        #   low_temp = 30;
        #   high_temp = 50;
        #   max_temp = 85;
        #   max_fan1_speed = 5500;
        #   min_fan1_speed = 4500;
        # };
      };
    };

    # powerManagement
    services.tlp = {
      enable = true;
      settings = {
        # The following prevents the battery from charging fully to
        # preserve lifetime. Run `tlp fullcharge` to temporarily force
        # full charge.
        # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 50;

        # 100 being the maximum, limit the speed of my CPU to reduce
        # heat and increase battery usage:
        # CPU_MAX_PERF_ON_AC = 80;
        # CPU_MAX_PERF_ON_BAT = 60;

        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;
      };
    };
    powerManagement = {
      # cpuFreqGovernor = "powersave";
      cpuFreqGovernor = "performance";
      powertop.enable = true;
      cpufreq.min = 800000;
      cpufreq.max = 2800000;
    };

    hardware = {
      # Enable webcam
      facetimehd.enable = true;

      cpu.intel.updateMicrocode = true;

      # Hardware video acceleration?
      opengl.extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
      opengl.extraPackages32 = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
    };
  };
}
