# Common configuration
{ config, pkgs, ... }:

let
  hostName = "gmbp";
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
    ./config/wayland.nix
  ];

  # Use the systemd-boot EFI boot loader.
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
    interfaces.wlp4s0.useDHCP = true;
  };

  # Macbook fan config
  services.mbpfan.enable = true;
  services.mbpfan.minFanSpeed = 4000;
  services.mbpfan.lowTemp = 35;
  services.mbpfan.maxFanSpeed = 6000;

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "mac";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = true;

  # GPU drivers
  # services.xserver.videoDrivers = [
  #   # "ati_unfree"
  #   # "ati"
  #   "amdgpu"
  #   "radeon"
  #   "ati"
  # ];
  # services.xserver.deviceSection = ''
  #   # Option "TearFree" "on"
  #   Option "TearFree" "true"
  # '';
  services.xserver.useGlamor = true;

  # Apparently this is currently only supported by ati_unfree drivers, not ati
  hardware.opengl.driSupport32Bit = false;

  # Fix font size in retina display
  hardware.video.hidpi.enable = true;
  services.xserver.dpi = 192;
  fonts.fontconfig.dpi = 192;

  # Update display brightness
  programs.light.enable = true;

  # Enable webcam
  # hardware = {
  #   facetimehd.enable = true;
  # };
}
