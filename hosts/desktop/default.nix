{ config, pkgs, lib, ... }:

let
  hostName = "gdesktop";
  isHidpi = true;
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  draculaTheme = import ../../config/mixins/dracula.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../config/mixins/nvidia.nix
    ../../config/xorg.nix
  ];

  config = {
    _userName = userName;
    _isHidpi = isHidpi;
    _homeDirectory = "/home/${userName}";
    _configDirectory = configDirectory;
    _theme = draculaTheme;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?

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

    environment = {
      sessionVariables = {
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";

        # QT_AUTO_SCREEN_SCALE_FACTOR = "0";
        # QT_FONT_DPI = "96";
        # QT_SCALE_FACTOR = "2";

        # GDK_DPI_SCALE = "0.5";
        # GDK_SCALE = "2";

        BSPWM_GAP = "25";
      };
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;
    };

    powerManagement.cpuFreqGovernor = "schedutil";

    networking = {
      hostName = hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.enp40s0.useDHCP = true;
      interfaces.wlp39s0.useDHCP = true;
    };

    # Fix windows dualboot clock
    time.hardwareClockInLocalTime = true;

    hardware = { video.hidpi.enable = true; };

    services.xserver = {
      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      # xkbVariant = "altgr-intl";

      # Setup monitors
      screenSection = ''
        # Select primary monitor
        # Option         "nvidiaXineramaInfoOrder" "DFP-0"
        # Option         "metamodes" "DP-0: 3840x2160_60 +0+0 {ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off, AllowGSYNCCompatible=On}"

        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
      '';
    };
  };
}
