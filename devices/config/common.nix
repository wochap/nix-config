{ config, pkgs, lib, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "22f6736e628958f05222ddaadd7df7818fe8f59d";
    ref = "release-20.09";
  };
  isMbp = config.networking.hostName == "gmbp";
  isWayland = config._displayServer == "wayland";
  localPkgs = import ./packages { pkgs = pkgs; };
  run-videochat = pkgs.writeScriptBin "run-videochat" (builtins.readFile ./scripts/run-videochat.sh);
in
{
  imports = [
    # Install home-manager
    (import "${home-manager}/nixos")

    ./users/gean.nix
  ];

  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options = {
    _displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland
      description = "Display server type, used by common config files.";
    };
  };

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?

    boot = {
      # Show nixos logo on boot/shutdown
      plymouth = {
        enable = true;
      };
      extraModprobeConfig = ''
        # Fix fn keys keychron
        options hid_apple fnmode=0
        # Enable IP Webcam
        options v4l2loopback devices=1 exclusive_caps=1
      '';
      kernelParams = [
        "hid_apple.fnmode=0"
      ];
      kernelModules = [
        "hid-apple"
        # Required for IP Webcam
        "v4l2loopback"
      ];
      extraModulePackages = [
        # Required for IP Webcam
        config.boot.kernelPackages.v4l2loopback
      ];
    };

    # Allows proprietary or unfree packages
    nixpkgs.config.allowUnfree = true;

    # Explicit PulseAudio support in applications
    nixpkgs.config.pulseaudio = true;

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
      sessionVariables = lib.mkMerge [
        {
          QT_QPA_PLATFORMTHEME = "qt5ct";
          ELECTRON_TRASH="trash-cli"; # fix vscode delete
        }
        (lib.mkIf isWayland {
          # Force GTK to use wayland
          GDK_BACKEND = "wayland";
          CLUTTER_BACKEND = "wayland";

          # Force firefox to use wayland
          MOZ_ENABLE_WAYLAND = "1";
        })
      ];
    };

    # List packages installed in system profile.
    environment.systemPackages = with pkgs; [
      # Tools
      # base-devel
      arandr # xrandr gui
      bc # calculator cli
      betterlockscreen # screen locker
      dos2unix
      evtest
      feh # image viewer
      ffmpeg-full # video codecs?
      fzf # fuzzy search
      git
      gnumake # make
      gotop # monitor system
      htop # monitor system
      inxi # check compositor running
      killall
      libqalculate
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      neofetch
      notify-desktop # test notifications
      nvtop # monitor system
      pciutils # lspci and others commands
      pulsemixer
      radeontop # monitor system
      ranger # file manager cli
      screenfetch # show system info
      scrot # screen capture
      trash-cli # required by vscode
      unzip
      vim
      wget
      xarchiver # archive manager required by thunar
      xclip
      xdotool # Fake keyboard/mouse input
      xlayoutdisplay # fix dpi
      xorg.xdpyinfo # show monitor info
      xorg.xeyes # check if app is running on wayland
      zip

      # IP Webcam related
      gnome3.zenity
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gstreamer
      gst_all_1.gstreamer.dev
      run-videochat
      v4l-utils

      # DE
      alttab # windows like alt + tab
      blueberry # bluetooth tray
      kitty # terminal
      networkmanager_dmenu # network manager cli
      pamixer # audio cli
      pavucontrol # audio gui
      playerctl # media player cli
      pywal # theme color generator cli
      systemd

      # Apps
      deluge # torrent client
      etcher # create booteable usbs
      filelight # view disk usage
      # gnome3.gnome-disk-utility
      # gnome3.gnome-system-monitor
      # gnome3.bijiben
      gnome3.cheese
      gnome3.file-roller # archive manager
      gnome3.gnome-calculator
      gnome3.gnome-font-viewer
      gnome3.gnome-sound-recorder
      gnome3.nautilus
      inkscape
      nomacs # image viewer/editor
      pick-colour-picker # color picker gui
      screenkey # show key pressed
      xfce.exo
      xfce.thunar # file manager
      xfce.thunar-archive-plugin
      xfce.thunar-volman
      xfce.xfconf
      zathura # PDF viewer
      zoom-us

      # Theme
      arc-icon-theme
      arc-theme
      capitaine-cursors
      hicolor-icon-theme
      nordic
      pantheon.elementary-icon-theme
      papirus-icon-theme
      qt5ct

      gsettings-desktop-schemas
      gtk-engine-murrine
      gtk_engines
      lxappearance
    ] ++ [
      localPkgs.eww
      localPkgs.whitesur-dark-icons
      localPkgs.zscroll # scroll text in shells
    ];

    fonts = {
      enableFontDir = true;
      enableGhostscriptFonts = true;
      enableDefaultFonts = true;
      fonts = with pkgs; [
        cantarell_fonts
        cascadia-code
        corefonts
        fira-code
        fira-code-symbols
        fira-mono
        font-awesome
        font-awesome_4
        gelasio
        hack-font
        jetbrains-mono
        mononoki
        noto-fonts
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        open-sans
        roboto
        roboto-slab
        siji
        source-code-pro
        terminus_font
        ttf_bitstream_vera
        ubuntu_font_family

        # Horizon theme
        (lib.mkIf (!isMbp) nerdfonts) # requires nvidia?
        # inconsolata-nerdfont
        # iosevka
        material-icons
      ] ;
      fontconfig = {
        allowBitmaps = true;
        defaultFonts = {
          serif = [ "Roboto Slab" ];
          sansSerif = [ "Roboto" ];
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
      openssh.authorizedKeys.keyFiles = [
        "~/.ssh/id_rsa.pub"
      ];
    };

    # Required by thunar
    services.gvfs.enable = true;
    services.tumbler.enable = true;

    # Generate login wallpapers
    # services.fractalart.enable = true;

    # Enable network manager
    networking = {
      wireless.enable = false;
      networkmanager.enable = true;
      nameservers = [
        "8.8.8.8"
      ];
      firewall = {
        enable = true;
        # allowedTCPPortRanges = [
        #   { from = 8080; to = 8090 }
        # ];
        allowedTCPPorts = [
          8080
          80
          22
        ];
      };
    };

    # Remember private keys
    programs.ssh.startAgent = true;

    # Enable wifi tray
    programs.nm-applet.enable = true;

    # Enable bluetooth tray
    hardware.bluetooth.enable = true;

    # Fix tearing?
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;
    hardware.opengl.driSupport32Bit = !isMbp;

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

    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    # Apply trim to SSDs
    services.fstrim.enable = true;
  };
}
