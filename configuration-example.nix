{ config, pkgs, ... }:

let
  dpi = 192;
in
{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enables wireless support via wpa_supplicant.
  networking.wireless.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp4s0.useDHCP = true;

  console = {
    # Increse font size for hidpi displays
    font = lib.mkIf (dpi == 192) "ter-132n";
    keyMap = "us";
    packages = [ pkgs.terminus_font ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.dpi = dpi;

  services.xserver.desktopManager.xterm.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
  ];

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  nix = {
    # Enable cachix
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
    binaryCaches = [
      "https://cache.nixos.org"
      "https://colemickens.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];

    # Enable flakes
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes recursive-nix
    '';

    trustedUsers = [ "@wheel" "root" ];
  };
}

