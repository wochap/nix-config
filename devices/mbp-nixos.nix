# Common configuration
{ config, pkgs, ... }:

let
  hostName = "gmbp";
  dpi = 192;
  nixos-hardware = builtins.fetchGit {
    url = "https://github.com/NixOS/nixos-hardware.git";
    rev = "fb1682bab43b9dd8daf43ae28f09e44541ce33a2";
    ref = "master";
  };
in
{
  imports = [
    # Include nixos-hardware
    (import "${nixos-hardware}/apple/macbook-pro/11-5")

    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    # Include configuration
    # ./config/wayland.nix
    ./config/xorg.nix
  ];

  # TODO: add missing stateVersion

  boot = {
    loader = {
      grub.enable = false;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    cleanTmpDir = true;
  };

  environment.systemPackages = with pkgs; [
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

  hardware = {
    video.hidpi.enable = true;
  };

  environment = {
    sessionVariables = {
      GDK_SCALE = "2";
    }
  };

  fonts.fontconfig.dpi = dpi;
  services = {
    xserver = {
      dpi = dpi;

      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      xkbVariant = "altgr-intl";
      # Macbook keyboard
      # xkbVariant = "mac";

      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;
      libinput.naturalScrolling = true;

      # GPU drivers
      videoDrivers = [
        "amdgpu"
      ];
      # Fix tearing
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };

    # Macbook fan config
    mbpfan = {
      enable = true;
      lowTemp = 35;
      maxFanSpeed = 6000;
      minFanSpeed = 4000;
    };
  };

  # Update display brightness
  programs.light.enable = true;

  # Enable webcam
  # hardware = {
  #   facetimehd.enable = true;
  # };
}
