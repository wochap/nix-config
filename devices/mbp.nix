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
    interfaces.wlp4s0.useDHCP = true;
  };

  # Macbook fan config
  services.mbpfan = {
    enable = true;
    minFanSpeed = 4000;
    lowTemp = 35;
    maxFanSpeed = 6000;
  };

  # Macbook keyboard
  services.xserver.xkbVariant = "mac";

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

  # Update display brightness
  programs.light.enable = true;

  # Enable webcam
  # hardware = {
  #   facetimehd.enable = true;
  # };
}
