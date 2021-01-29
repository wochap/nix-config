{ config, pkgs, ... }:

let
  hostName = "gasus";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix

      # Include common configuration
      ./config/default.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.cleanTmpDir = true;

  # Enables wireless support via wpa_supplicant.
  networking.wireless.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp4s0.useDHCP = true;

  # Set hostname.
  networking = {
    inherit hostName;
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Enable dual gpu
  hardware.bumblebee.enable = true;
  hardware.bumblebee.driver = "nouveau";

  hardware.opengl.enable = true;

  # Update display brightness
  programs.light.enable = true;
}
