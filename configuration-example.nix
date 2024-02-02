{ config, pkgs, ... }:

let
  userName = "gean";
  wifiInterface = "wlp4s0";
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Luks, if you encrypted your disks
  # boot.initrd.luks.devices."luks-5e55f437-0358-410c-bcc5-0ee81f77631f".device = "/dev/disk/by-uuid/5e55f437-0358-410c-bcc5-0ee81f77631f";

  # Enable network manager
  networking.wireless.enable = false; # Disable wpa_supplicant
  networking.enableIPv6 = false;
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true; # Install nmtui
  networking.interfaces.${wifiInterface}.useDHCP = true;

  # Set your time zone.
  time.timeZone = "America/Panama";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ git vim wget git-crypt ];

  networking.firewall.enable = false;

  nix.settings = {
    # Enable flakes
    experimental-features = [ "nix-command" "flakes" "recursive-nix" ];

    # Enable cachix
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://hyprland.cachix.org"
      "https://nixpkgs-python.cachix.org"
      # "http://192.168.1.100:8080"
    ];

    trusted-users = [ "@wheel" "root" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${userName} = {
    isNormalUser = true;
    description = "gean";
    home = "/home/gean";
    extraGroups =
      [ "input" "audio" "disk" "networkmanager" "storage" "video" "wheel" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
