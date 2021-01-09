# Common configuration
{ config, pkgs, hostName ? "unknown", ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "22f6736e628958f05222ddaadd7df7818fe8f59d"; # CHANGEME 
    ref = "release-20.09";
  };
in
{
  imports = [
    # Setup home-manager
    (import "${home-manager}/nixos")
  ];

  # Allows proprietary or unfree package
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "America/Lima";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.gean = {
    password = "123456";
    isNormalUser = true;
    extraGroups = [ 
      "wheel" # Enable ‘sudo’ for the user.
    ];
    # TODO: setup openssh
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    git
    kitty
    # firefox
  ];

  # List services that you want to enable:
  services.xserver.enable = true;
  # services.xserver.windowManager.bspwm.enable = true;
  services.xserver.displayManager.lightdm.enable = false;

  # Setup fonts
  # fonts = {
  #   enableDefaultFonts = true;
  #   fonts = with pkgs; [
  #     fira-code
  #     hack-font
  #   ];
  # };

  # nix.trustedUsers = [ "root" "gean" ];

  # Setup home-manager
  home-manager.users.gean = (import ./home-manager/home.nix { 
    inherit pkgs config hostName;
  } );

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
