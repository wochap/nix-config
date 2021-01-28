{ config, pkgs, hostName ? "unknown", ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "22f6736e628958f05222ddaadd7df7818fe8f59d";
    ref = "release-20.09";
  };
in
{
  imports = [
    # Install home-manager
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

  # Enable wayland
  services.xserver.displayManager.gdm.nvidiaWayland = true;
  services.xserver.displayManager.gdm.enable = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    git
    kitty
    killall
    gnumake # make
    xfce.thunar # file manager
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    screenfetch
    unzip
    zip

    lxappearance
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    arc-theme
    pantheon.elementary-icon-theme
  ];

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
      siji
      material-icons
      material-design-icons
      corefonts
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.gean = {
    password = "123456";
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "docker"
      "video"
      "audio"
      "networkmanager"
    ];
  };
  # Setup users config
  home-manager.users.gean = (import ./users/gean.nix {
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
