{ config, pkgs, lib, ... }:
let
  hostName = "gdesktop";
  # Common values are 96, 120 (25% higher), 144 (50% higher), 168 (75% higher), 192 (100% higher)
  # xlayoutdisplay throws 156
  dpi = 144;
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    # Include configuration
    ./config/xorg.nix
  ];

  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options = {
    _displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland
      description = "Display server type, used by common config files.";
    };
  };

  config = {
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

    hardware = {
      video.hidpi.enable = true;
    };

    fonts.fontconfig.dpi = dpi;
    services.xserver = {
      # dpi = dpi;

      videoDrivers = [
        "modesetting"
        # "nvidiaBeta"
        "nvidia"
      ];

      # Test 1
      serverLayoutSection = ''
        Screen      0  "Screen0" 0 0
        Option         "Xinerama" "0"
      '';
      extraConfig = ''
        Section "Monitor"
          # HorizSync source: edid, VertRefresh source: edid
          Identifier     "Monitor0"
          VendorName     "Unknown"
          ModelName      "LG Electronics LG HDR 4K"
          HorizSync       135.0 - 135.0
          VertRefresh     40.0 - 61.0
          Option         "DPMS"
        EndSection

        Section "Device"
          Identifier     "Device0"
          Driver         "nvidia"
          VendorName     "NVIDIA Corporation"
          BoardName      "GeForce GTX 1650 SUPER"
        EndSection

        Section "Screen"
          Identifier     "Screen0"
          Device         "Device0"
          Monitor        "Monitor0"
          DefaultDepth    24
          Option         "Stereo" "0"
          Option         "nvidiaXineramaInfoOrder" "DFP-0"
          # Switch between multiple monitor setup
          # Option         "metamodes" "DP-0: 3840x2160_60 +1920+0 {AllowGSYNCCompatible=On}, DP-2: 1920x1080_144 +0+0 {AllowGSYNCCompatible=On}"
          Option         "metamodes" "DP-0: 3840x2160_60 +0+0 {AllowGSYNCCompatible=On}"
          Option         "SLI" "Off"
          Option         "MultiGPU" "Off"
          Option         "BaseMosaic" "off"
          SubSection     "Display"
              Depth       24
          EndSubSection
          Option         "UseEdidDpi" "FALSE"
          Option         "DPI" "144 x 144"
        EndSection
      '';

      # # Test 2
      # serverLayoutSection = ''
      #   Screen      0  "Screen0" 0 0
      #   Screen      1  "Screen1" RightOf "Screen0"
      #   Option         "Xinerama" "0"
      # '';
      # serverFlagsSection = ''
      #   Option "DefaultServerLayout" "Layout0"
      # '';
      # extraConfig = ''
      #   Section "ServerLayout"
      #     Identifier     "Layout0"
      #     Screen      0  "Screen0" 0 0
      #     Screen      1  "Screen1" LeftOf "Screen0"
      #     Option         "Xinerama" "0"
      #   EndSection

      #   Section "Monitor"
      #     # HorizSync source: edid, VertRefresh source: edid
      #     Identifier     "Monitor0"
      #     VendorName     "Unknown"
      #     ModelName      "LG Electronics LG HDR 4K"
      #     HorizSync       135.0 - 135.0
      #     VertRefresh     40.0 - 61.0
      #     Option         "DPMS"
      #   EndSection

      #   Section "Monitor"
      #     # HorizSync source: edid, VertRefresh source: edid
      #     Identifier     "Monitor1"
      #     VendorName     "Unknown"
      #     ModelName      "AUS ASUS VP249"
      #     HorizSync       180.0 - 180.0
      #     VertRefresh     48.0 - 144.0
      #     Option         "DPMS"
      #   EndSection

      #   Section "Device"
      #       Identifier     "Device0"
      #       Driver         "nvidia"
      #       VendorName     "NVIDIA Corporation"
      #       BoardName      "GeForce GTX 1650 SUPER"
      #       BusID          "PCI:43:0:0"
      #       Screen          0
      #   EndSection

      #   Section "Device"
      #       Identifier     "Device1"
      #       Driver         "nvidia"
      #       VendorName     "NVIDIA Corporation"
      #       BoardName      "GeForce GTX 1650 SUPER"
      #       BusID          "PCI:43:0:0"
      #       Screen          1
      #   EndSection

      #   Section "Screen"
      #     Identifier     "Screen0"
      #     Device         "Device0"
      #     Monitor        "Monitor0"
      #     DefaultDepth    24
      #     Option         "Stereo" "0"
      #     Option         "nvidiaXineramaInfoOrder" "DFP-0"
      #     Option         "metamodes" "DP-0: 3840x2160_60 +0+0 {AllowGSYNCCompatible=On}"
      #     Option         "SLI" "Off"
      #     Option         "MultiGPU" "Off"
      #     Option         "BaseMosaic" "off"
      #     SubSection     "Display"
      #         Depth       24
      #     EndSubSection
      #     Option         "UseEdidDpi" "FALSE"
      #     Option         "DPI" "144 x 144"
      #   EndSection

      #   Section "Screen"
      #     Identifier     "Screen1"
      #     Device         "Device1"
      #     Monitor        "Monitor1"
      #     DefaultDepth    24
      #     Option         "Stereo" "0"
      #     Option         "metamodes" "DP-2: 1920x1080_144 +0+0 {AllowGSYNC=Off, AllowGSYNCCompatible=On}"
      #     Option         "SLI" "Off"
      #     Option         "MultiGPU" "Off"
      #     Option         "BaseMosaic" "off"
      #     SubSection     "Display"
      #         Depth       24
      #     EndSubSection
      #   EndSection
      # '';
    };
  };
}
