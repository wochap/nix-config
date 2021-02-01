{ config, pkgs, ... }:

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

    ./users/gean.nix
  ];

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?

    boot.plymouth = {
      enable = true;
    };

    # Fix fn keys
    boot.extraModprobeConfig = ''
      options hid_apple fnmode=0
    '';
    boot.kernelParams = [
      "hid_apple.fnmode=0"
    ];
    boot.kernelModules = [ "hid-apple" ];

    # Allows proprietary or unfree package
    nixpkgs.config.allowUnfree = true;

    # Set your time zone.
    time.timeZone = "America/Lima";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      earlySetup = true; # hidpi + luks-open  # TODO : STILL NEEDED?
      keyMap = "us";
    };

    # List packages installed in system profile.
    environment.systemPackages = with pkgs; [
      git
      gnumake # make
      nvtop
      gotop
      htop
      inxi # check compositor running
      killall
      screenfetch
      unzip
      vim
      wget
      xarchiver
      xfce.thunar # file manager
      xfce.thunar-archive-plugin
      xfce.thunar-volman
      xfce.gvfs
      xorg.xdpyinfo
      zip
      evtest
      arandr # xrandr gui
      notify-desktop # test notifications

      # DE
      gvfs
      pywal # theme color generator
      alttab
      kitty
      blueberry
      pavucontrol # audio gui
      pamixer # control audio
      volumeicon # audio tray + gui
      nomacs # image viewer/editor
      networkmanager_dmenu
      pick-colour-picker
      screenkey

      # Theme
      gnome3.gnome-tweaks
      qt5ct
      lxappearance
      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      arc-theme
      pantheon.elementary-icon-theme
      capitaine-cursors
      arc-icon-theme
      hicolor-icon-theme
    ];

    fonts = {
      enableDefaultFonts = true;
      fonts = with pkgs; [
        nerdfonts
        noto-fonts
        cascadia-code
        corefonts
        fira-code
        fira-code-symbols
        fira-mono
        font-awesome
        gelasio
        hack-font
        iosevka
        jetbrains-mono
        material-design-icons
        material-icons
        noto-fonts noto-fonts-cjk noto-fonts-emoji
        siji
        source-code-pro
        ttf_bitstream_vera
        ubuntu_font_family
      ];
      fontconfig = {
        allowBitmaps = true;
        defaultFonts = {
          serif = [ "Ubuntu" ];
          sansSerif = [ "Ubuntu" ];
          monospace = [ "Fira Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    nix.autoOptimiseStore = true;
    nix.trustedUsers = [ "@wheel" "root" ];
    security.sudo.wheelNeedsPassword = false;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.extraUsers.gean = {
      shell = pkgs.fish;
      password = "123456";
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
        "video"
        "audio"
        "networkmanager"
      ];
    };

    # Setup DE bspwm and sxhkdrc
    environment = {
      sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        ELECTRON_TRASH="gvfs";
      };
      etc = {
        bspwmrc = {
          source = ./dotfiles/bspwmrc;
          mode = "0755";
        };
        sxhkdrc = {
          source = ./dotfiles/sxhkdrc;
          mode = "0755";
        };
        sxhkd-help = {
          source = ./scripts/sxhkd-help.sh;
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
        lightdm.enable = true;
      };
    };
    services.picom = {
      enable = true;
      vSync = true;
    };
    services.gvfs.enable = true;

    # Enable wifi tray
    networking = {
      wireless.enable = false;
      networkmanager.enable = true;
      nameservers = [
        "8.8.8.8"
      ];
    };
    programs.nm-applet.enable = true;

    # Enable bluetooth tray
    hardware.bluetooth.enable = true;

    # Enable audio
    sound.enable = true;
    hardware.pulseaudio.enable = true;
  };
}
