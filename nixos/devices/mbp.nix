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
  imports =
    [ # Include nixos-hardware
      (import "${nixos-hardware}/apple/macbook-pro/11-5")
      # "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/apple/macbook-pro/11-5"
      # <nixos-hardware/apple/macbook-pro/11-5>

      # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix

      # Include common configuration
      (import ../common.nix {
        inherit pkgs config hostName;
      })
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.cleanTmpDir = true;

  # Enables wireless support via wpa_supplicant.
  networking.wireless.enable = true;
  # networking.networkmanager.enable = true;
  # programs.nm-applet.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp4s0.useDHCP = true;

  # Set hostname.
  networking = { 
    inherit hostName;
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

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = true;

  # GPU drivers
  services.xserver.videoDrivers = [ 
    # "ati_unfree"
    "ati"
  ];
  services.xserver.deviceSection = ''
    Option "TearFree" "on"
  '';
  services.xserver.useGlamor = true;

  # Apparently this is currently only supported by ati_unfree drivers, not ati
  hardware.opengl.driSupport32Bit = false;

  # Fix font size in retina display
  hardware.video.hidpi.enable = true;
  # services.xserver.dpi = 220;
  # fonts.fontconfig.dpi = 220;
  # services.xserver.autorun = true;
  # mbp: 762x476
  # services.xserver.monitorSection = ''
  #   DisplaySize 508 317
  # '';
  services.xserver.extraDisplaySettings = ''
    Virtual 1920 1200
  '';

  # Update display brightness
  programs.light.enable = true;

  # Enable webcam
  # hardware = {
  #   facetimehd.enable = true;
  # };

  # TODO: enable acpid?
}
