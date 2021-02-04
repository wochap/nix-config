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

    # Show nixos logo on boot/shutdown
    boot.plymouth = {
      enable = true;
    };

    # Fix fn keys keychron
    boot.extraModprobeConfig = ''
      options hid_apple fnmode=0
    '';
    boot.kernelParams = [
      "hid_apple.fnmode=0"
    ];
    boot.kernelModules = [ "hid-apple" ];

    # Allows proprietary or unfree packages
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

    environment = {
      sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        ELECTRON_TRASH="trash-cli"; # fix vscode delete
      };
    };

    # List packages installed in system profile.
    environment.systemPackages = with pkgs; [
      # Tools
      arandr # xrandr gui
      bc # calculator cli
      evtest
      ffmpeg-full # video codecs?
      git
      gnumake # make
      gotop
      htop
      inxi # check compositor running
      killall
      mpd
      mpd_clientlib # mpd module
      notify-desktop # test notifications
      nvtop
      pciutils # lspci and others commands
      radeontop
      screenfetch # show system info
      trash-cli # required by vscode
      unzip
      vim
      wget
      xarchiver # required by thunar
      xclip
      xfce.gvfs
      xfce.thunar # file manager
      xfce.thunar-archive-plugin
      xfce.thunar-volman
      xlayoutdisplay # fix dpi
      xorg.xdpyinfo # show monitor info
      xorg.xeyes # check if app is running on wayland
      zip

      # DE
      alttab # windows like alt + tab
      blueberry # bluetooth tray
      kitty # terminal
      networkmanager_dmenu # network manager cli
      pamixer # audio cli
      pavucontrol # audio gui
      pywal # theme color generator cli
      volumeicon # audio tray + gui

      # Apps
      etcher # create booteable usbs
      nomacs # image viewer/editor
      pick-colour-picker # color picker gui
      screenkey # show key pressed
      filelight # view disk usage
      deluge # torrent client

      # Theme
      arc-icon-theme
      arc-theme
      capitaine-cursors
      hicolor-icon-theme
      pantheon.elementary-icon-theme
      papirus-icon-theme
      qt5ct

      gsettings-desktop-schemas
      gtk-engine-murrine
      gtk_engines
      lxappearance
    ];

    fonts = {
      enableDefaultFonts = true;
      fonts = with pkgs; [
        # nerdfonts # requires nvidia?
        cascadia-code
        corefonts
        fira-code
        fira-code-symbols
        fira-mono
        font-awesome
        font-awesome_4
        gelasio
        hack-font
        iosevka
        jetbrains-mono
        material-design-icons
        material-icons
        noto-fonts
        noto-fonts noto-fonts-cjk noto-fonts-emoji
        siji
        source-code-pro
        terminus_font
        ttf_bitstream_vera
        ubuntu_font_family
        work-sans
      ];
      fontconfig = {
        allowBitmaps = true;
        defaultFonts = {
          serif = [ "Work Sans" ];
          sansSerif = [ "Work Sans" ];
          monospace = [ "Fira Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    # Links /libexec from derivations to /run/current-system/sw
    environment.pathsToLink = [ "/libexec" ];

    nix = {
      trustedUsers = [ "@wheel" "root" ];

      # Clear nixos store
      autoOptimiseStore = true;
    };

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.extraUsers.gean = {
      shell = pkgs.fish;
      uid = 1000;
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

    # Enable network manager
    networking = {
      wireless.enable = false;
      networkmanager.enable = true;
      nameservers = [
        "8.8.8.8"
      ];
    };

    # Enable wifi tray
    programs.nm-applet.enable = true;

    # Enable bluetooth tray
    hardware.bluetooth.enable = true;

    # Fix tearing?
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;
    hardware.opengl.driSupport32Bit = true;

    # Enable audio
    sound.enable = true;
    hardware.pulseaudio.enable = true;
    hardware.pulseaudio.support32Bit = true;

    # better timesync for unstable internet connections
    # services.chrony.enable = true;
    # services.timesyncd.enable = false;

    services.xserver = {
      layout = "us";
      xkbOptions = "eurosign:e";
    };
  };
}
