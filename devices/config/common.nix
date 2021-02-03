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
      pciutils # lspci and others commands
      git
      gnumake # make
      nvtop
      radeontop
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
      xlayoutdisplay # fix dpi
      ffmpeg-full
      bc # calculator cli

      # DE
      pywal # theme color generator
      alttab
      kitty # terminal
      blueberry # bluetooth tray
      pavucontrol # audio gui
      pamixer # audio cli
      volumeicon # audio tray + gui
      networkmanager_dmenu # for rofi
      pick-colour-picker # color picker gui

      # Apps
      nomacs # image viewer/editor
      screenkey # show key pressed
      etcher # create booteable usbs

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
        # nerdfonts
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

    # links /libexec from derivations to /run/current-system/sw
    environment.pathsToLink = [ "/libexec" ];

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

    # Required by thunar
    services.gvfs.enable = true;

    # Generate login wallpapers
    services.fractalart.enable = true;

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

    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;

    # Enable audio
    sound.enable = true;
    hardware.pulseaudio.enable = true;
    hardware.pulseaudio.support32Bit = true;

    # better timesync for unstable internet connections
    # services.chrony.enable = true;
    # services.timesyncd.enable = false;
  };
}
