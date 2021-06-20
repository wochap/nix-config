{ config, pkgs, lib, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "148d85ee8303444fb0116943787aa0b1b25f94df";
    ref = "release-21.05";
  };
  isHidpi = config._isHidpi;
  isMbp = config.networking.hostName == "gmbp";
in
{
  imports = [
    (import "${home-manager}/nixos")
  ];

  config = {
    nixpkgs.config.packageOverrides = pkgs: rec {
      unstable = import (builtins.fetchTarball {
        url = https://github.com/nixos/nixpkgs/archive/2c2b33c326a3faf5dc86e373dfafe0dcf3eb5136.tar.gz;
        sha256 = "0wpfllarf1s0bbs85f9pa4nihf94hscpzvk5af4a1zxgq2l9c8r6";
      }) {
        # pass the nixpkgs config to the unstable alias
        # to ensure `allowUnfree = true;` is propagated:
        config = config.nixpkgs.config;
      };
      android = import (builtins.fetchTarball {
        url = https://github.com/tadfisher/android-nixpkgs/archive/0c4e5a01dbd4c8c894f2186a7c582abf55a43c5e.tar.gz;
        sha256 = "0x56nh4nxx5hvpi7aq66v7xm9mzn4b2gs50z60w8c3ciimjlpip8";
      }) {
        channel = "stable";
      };
    };

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
