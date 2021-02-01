{ config, pkgs, ... }:
let
  hostName = "gdesktop";
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    # Include configuration
    ./config/default.nix
  ];

  config = {
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.cleanTmpDir = true;

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
      opengl.enable = true;
      opengl.driSupport32Bit = false;
      # video.hidpi.enable = true;
    };

    services.xserver = {
      videoDrivers = [
        "nvidia"
        "nouveau"
      ];

      screenSection = ''
        Option "metamodes" "1920x1080_144 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}"
        Option "AllowIndirectGLXProtocol" "off"
        Option "TripleBuffer" "on"
      '';
      # serverLayoutSection = ''
      #   Screen 1 "Screen1" RightOf "Screen0"
      # '';
      # extraConfig = ''
      #   Section "Monitor"
      #     # HorizSync source: edid, VertRefresh source: edid
      #     Identifier     "Monitor1"
      #     VendorName     "Unknown"
      #     ModelName      "LG Electronics LG HDR 4K"
      #     HorizSync       30.0 - 135.0
      #     VertRefresh     40.0 - 61.0
      #     Option         "DPMS"
      #   EndSection

      #   Section "Device"
      #     Identifier     "Device1"
      #     Driver         "nvidia"
      #     VendorName     "NVIDIA Corporation"
      #     BoardName      "GeForce GTX 1650 SUPER"
      #     BusID          "PCI:43:0:0"
      #     Screen          1
      #   EndSection

      #   Section "Screen"
      #     Identifier     "Screen1"
      #     Device         "Device1"
      #     Monitor        "Monitor1"
      #     DefaultDepth    24
      #     Option         "Stereo" "0"
      #     Option         "metamodes" "HDMI-0: nvidia-auto-select +0+0 {viewportin=2560x1600, viewportout=3456x2160+192+0, AllowGSYNC=Off}"
      #     Option         "SLI" "Off"
      #     Option         "MultiGPU" "Off"
      #     Option         "BaseMosaic" "off"
      #     SubSection     "Display"
      #       Depth       24
      #     EndSubSection
      #   EndSection
      # '';

      # Configure keymap in X11
      layout = "us";
      xkbOptions = "eurosign:e";
    };
  };
}
