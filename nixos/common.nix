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
    killall
    rofi # app launcher
    gnumake # make
    xfce.thunar # file manager
    screenfetch
  ];

  # Setup bspwm and sxhkdrc for all users
  environment = {
    etc = {
      bspwmrc = {
        source = ./dotfiles/bspwmrc;
        mode = "0755";
      };
      sxhkdrc = {
        source = ./dotfiles/sxhkdrc;
        mode = "0755";
      };
    };
  };
  services.xserver = {
    enable = true;
    windowManager.bspwm = {
      enable = true;
      configFile = "/etc/bspwmrc";
      sxhkd.configFile = "/etc/sxhkdrc";
    };
    displayManager = {
      defaultSession = "none+bspwm";
    };
  };
  services.xserver.displayManager.lightdm.enable = false;

  # Setup picom
  services.picom = {
    enable = true;
    vSync = true;
  };

  # Setup global fonts
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      ubuntu_font_family
      fira-mono
      fira-code
      fira-code-symbols
      hack-font
      font-awesome
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Ubuntu" ];
        sansSerif = [ "Ubuntu" ];
        monospace = [ "Fira Mono" ];
      };
    };
  };

  nix.trustedUsers = [ "root" "gean" ];

  # Setup users
  home-manager.users.gean = (import ./users/gean.nix { 
    inherit pkgs config hostName;
  } );
  home-manager.users.root = (import ./users/root.nix { 
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
