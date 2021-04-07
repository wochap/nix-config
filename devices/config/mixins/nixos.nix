{ config, pkgs, lib, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "22f6736e628958f05222ddaadd7df7818fe8f59d";
    ref = "release-20.09";
  };
  isHidpi = config._isHidpi;
  isMbp = config.networking.hostName == "gmbp";
in
{
  imports = [
    (import "${home-manager}/nixos")
  ];

  config = {
    # Allows proprietary or unfree packages
    nixpkgs.config.allowUnfree = true;

    # Explicit PulseAudio support in applications
    nixpkgs.config.pulseaudio = true;

    # Set your time zone.
    time.timeZone = "America/Lima";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      font = if isHidpi then "ter-132n" else "Lat2-Terminus16";
      earlySetup = true;
      keyMap = "us";
      packages = [
        pkgs.terminus_font
      ];
    };

    nix = {
      gc.automatic = true;

      trustedUsers = [ "@wheel" "root" ];

      # Clear nixos store
      autoOptimiseStore = true;
    };

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    # Enable bluetooth
    hardware.bluetooth.enable = true;

    # Enable OpenGL
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;
    # Hardware video acceleration
    hardware.opengl.extraPackages = with pkgs; [
      libvdpau
      vaapiVdpau
      libvdpau-va-gl
    ];
    hardware.opengl.driSupport32Bit = !isMbp;

    # Enable audio
    sound.enable = true;
    hardware.pulseaudio.enable = true;
    # hardware.pulseaudio.support32Bit = true;

    # Apply trim to SSDs
    services.fstrim.enable = true;

    documentation.man.generateCaches = true;
    documentation.dev.enable = true;
  };
}
