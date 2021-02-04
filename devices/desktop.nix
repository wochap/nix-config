{ config, pkgs, ... }:
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
      dpi = dpi;

      videoDrivers = [
        "nvidiaBeta"
        # "nvidia"
      ];

      screenSection = ''
        # Option "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=Off}"
        # Option "metamodes" "3840x2160_60 +0+0 {ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off, AllowGSYNCCompatible=On}"
        # Option "TripleBuffer" "on"
      '';
      # serverFlagsSection = ''
      #   Option "DefaultServerLayout" "Layout0"
      # '';
      # extraConfig = ''
      #   Section "ServerLayout"
      #       Identifier     "Layout0"
      #       Screen      0  "Screen0" 0 0
      #       Option         "Xinerama" "0"
      #   EndSection

      #   Section "Monitor"
      #       # HorizSync source: edid, VertRefresh source: edid
      #       Identifier     "Monitor0"
      #       VendorName     "Unknown"
      #       ModelName      "LG Electronics LG HDR 4K"
      #       HorizSync       135.0 - 135.0
      #       VertRefresh     40.0 - 61.0
      #       Option         "DPMS"
      #   EndSection

      #   Section "Device"nb
      #       Identifier     "Device0"
      #       Driver         "nvidia"
      #       VendorName     "NVIDIA Corporation"
      #       BoardName      "GeForce GTX 1650 SUPER"
      #   EndSection

      #   Section "Screen"
      #       Identifier     "Screen0"
      #       Device         "Device0"
      #       Monitor        "Monitor0"
      #       DefaultDepth    24
      #       Option         "Stereo" "0"
      #       Option         "nvidiaXineramaInfoOrder" "DFP-2"
      #       Option         "metamodes" "3840x2160_60 +0+0; 1920x1080 +0+0 {viewportin=3840x2160, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}"
      #       Option         "SLI" "Off"
      #       Option         "MultiGPU" "Off"
      #       Option         "BaseMosaic" "off"
      #       SubSection     "Display"
      #           Depth       24
      #       EndSubSection
      #       Option         "AllowIndirectGLXProtocol" "off"
      #       Option         "TripleBuffer" "on"
      #       Option         "DPI" "144 x 144"
      #   EndSection
      # '';
      # screenSection = ''
      #   Option "metamodes" "1920x1080_144 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}"
      #   Option "AllowIndirectGLXProtocol" "off"
      #   Option "TripleBuffer" "on"
      # '';
      # serverLayoutSection = ''
      #   Screen "Screen-nvidia[0]" RightOf "Screen-nvidia[1]"
      # '';
      # extraConfig = ''
      #   Section "ServerLayout"
      #       Identifier     "Layout0"
      #       Screen         "Screen-nvidia[1]"
      #   EndSection

      #   Section "Monitor"
      #     Identifier     "Monitor[1]"
      #     VendorName     "Unknown"
      #     ModelName      "LG Electronics LG HDR 4K"
      #     HorizSync       30.0 - 135.0
      #     VertRefresh     40.0 - 61.0
      #     Option         "DPMS"
      #   EndSection

      #   Section "Device"
      #     Identifier     "Device-nvidia[1]"
      #     Driver         "nvidia"
      #     VendorName     "NVIDIA Corporation"
      #     BoardName      "GeForce GTX 1650 SUPER"
      #   EndSection

      #   Section "Screen"
      #     Identifier     "Screen-nvidia[1]"
      #     Device         "Device-nvidia[1]"
      #     Monitor        "Monitor[1]"
      #     DefaultDepth    24
      #     Option         "Stereo" "0"
      #     Option         "nvidiaXineramaInfoOrder" "DFP-4"
      #     Option         "metamodes" "HDMI-0: nvidia-auto-select +0+0 {viewportin=2560x1600, viewportout=3456x2160+192+0, ForceCompositionPipeline=On, AllowGSYNC=Off}"
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
