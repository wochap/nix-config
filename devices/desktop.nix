{ config, pkgs, lib, ... }:
let
  hostName = "gdesktop";
  # Common values are 96, 120 (25% higher), 144 (50% higher), 168 (75% higher), 192 (100% higher)
  # xlayoutdisplay throws 156
  dpi = 144;
  userName = "gean";
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    # Cachix required by doom-emacs
    /etc/nixos/cachix.nix

    ./config/mixins/nvidia.nix
    ./config/xorg.nix
  ];

  config = {
    _userName = userName;
    _isHidpi = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?

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
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;
    };

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

    hardware = {
      video.hidpi.enable = true;
    };

    fonts.fontconfig.dpi = dpi;

    services.xserver = {
      dpi = dpi;

      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      xkbVariant = "altgr-intl";

      # Setup monitors
      screenSection = ''
        # Select primary monitor
        Option         "nvidiaXineramaInfoOrder" "DFP-0"
        # Default multiple monitor setup
        Option         "metamodes" "DP-0: 3840x2160_60 +0+0 {ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off, AllowGSYNCCompatible=On}"
      '';
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
  };
}
