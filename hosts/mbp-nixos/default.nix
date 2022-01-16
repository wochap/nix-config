{ config, pkgs, lib, inputs, ... }:

let
  hostName = "gmbp";
  # Common values are 96, 120 (25% higher), 144 (50% higher), 168 (75% higher), 192 (100% higher)
  isHidpi = true;
  dpi = 192;
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
in {
  imports = [
    (import "${inputs.nixos-hardware}/apple/macbook-pro/11-5")
    /etc/nixos/hardware-configuration.nix
    # ./config/wayland.nix
    ../../config/xorg.nix
  ];

  config = {
    _userName = userName;
    _isHidpi = isHidpi;
    _configDirectory = configDirectory;

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

      xresources.properties = lib.mkIf (isHidpi) {
        "Xft.dpi" = dpi;
        "Xft.antialias" = 1;
        "Xft.rgba" = "rgb";
      };
    };

    boot = {
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;
    };

    environment.sessionVariables = {
      GDK_DPI_SCALE = "0.5";
      GDK_SCALE = "2";
      WIFI_DEVICE = "wlp4s0";
      BSPWM_GAP = "25";
    };

    environment.systemPackages = with pkgs;
      [
        radeontop # monitor system amd
      ];

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
        # xkbVariant = "altgr-intl";
        # Macbook keyboard
        xkbVariant = "mac";

        # Enable touchpad support (enabled default in most desktopManager).
        libinput.enable = true;
        libinput.touchpad.naturalScrolling = true;
        libinput.touchpad.tapping = false;

        # GPU drivers
        videoDrivers = [ "amdgpu" ];

        deviceSection = ''
          # does it fix screen tearing? maybe...
          # Option         "NoLogo" "1"
          # Option         "RenderAccel" "1"
          # Option         "TripleBuffer" "true"
          # Option         "MigrationHeuristic" "greedy"
          # Option         "AccelMethod" "sna"
          Option         "TearFree"    "true"
        '';
      };

      # Macbook fan config
      mbpfan = {
        enable = true;
        lowTemp = 30;
        maxFanSpeed = 5500;
        minFanSpeed = 4000;
      };
    };

    # Update display brightness
    programs.light.enable = true;

    # Enable webcam
    # hardware = {
    #   facetimehd.enable = true;
    # };
  };

}
