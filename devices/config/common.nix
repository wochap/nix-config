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
      dex # execute DesktopEntry files
      dos2unix
      evtest
      feh # image viewer
      ffmpeg-full # music/video codecs?
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
      neofetch # print computer info
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
      xclip # clipboard cli
      xdotool # fake keyboard/mouse input
      xlayoutdisplay # fix dpi
      xorg.xdpyinfo # show monitor info
      xorg.xev # get key actual name
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
      betterlockscreen # screen locker
      blueberry # bluetooth tray
      kitty # terminal
      # networkmanager_dmenu # network manager cli
      pamixer # audio cli
      pavucontrol # audio settings gui
      playerctl # media player cli
      # pywal # theme color generator cli
      systemd

      # Apps
      deluge # torrent client
      etcher # create booteable usbs
      filelight # view disk usage
      # gnome3.gnome-disk-utility
      # gnome3.gnome-system-monitor
      # gnome3.bijiben
      gnome3.cheese # test webcam
      gnome3.eog # image viewer
      gnome3.file-roller # archive manager
      gnome3.geary # email client
      gnome3.gnome-calculator
      gnome3.gnome-calendar
      gnome3.gnome-control-center # add google account for geary and calendar
      gnome3.gnome-font-viewer
      gnome3.gnome-sound-recorder # test microphone
      inkscape # photo editor cli/gui
      nomacs # image viewer/editor
      pick-colour-picker # color picker gui
      screenkey # show key pressed
      simplenote
      xfce.exo
      xfce.thunar # file manager
      xfce.thunar-archive-plugin
      xfce.thunar-volman # auto mont devices
      xfce.xfconf # where thunar settings are saved
      zathura # PDF viewer
      zoom-us

      # Themes
      capitaine-cursors
      papirus-icon-theme

      # Themes settings
      gnome3.gsettings-desktop-schemas
      gtk-engine-murrine
      gtk_engines
      lxappearance
      qt5ct
    ] ++ [
      localPkgs.eww # custom widgets daemon
      localPkgs.whitesur-dark-icons
      localPkgs.zscroll # scroll text in shells
    ];

    fonts = {
      enableFontDir = true;
      enableGhostscriptFonts = true;
      enableDefaultFonts = true;
      fonts = with pkgs; [
        # inconsolata-nerdfont
        # iosevka
        corefonts # basic fonts for office
        fira-code
        fira-code-symbols
        fira-mono
        font-awesome
        font-awesome_4
        hack-font
        material-icons
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        open-sans
        roboto
        roboto-slab
        siji
        terminus_font

        # Horizon theme
        (lib.mkIf (!isMbp) nerdfonts) # requires nvidia?
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

    # Enable network manager
    networking = {
      enableIPv6 = false;
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

    # Add wifi tray
    programs.nm-applet.enable = true;

    # Enable bluetooth
    hardware.bluetooth.enable = true;

    # Fix tearing?
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;
    hardware.opengl.driSupport32Bit = !isMbp;

    # Enable audio
    sound.enable = true;
    hardware.pulseaudio.enable = true;
    hardware.pulseaudio.support32Bit = true;

    services.xserver = {
      layout = "us";
      xkbOptions = "eurosign:e";
    };

    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    # Apply trim to SSDs
    services.fstrim.enable = true;

    # Required for gnome calendar and geary
    services.gnome3.evolution-data-server.enable = true;
    services.gnome3.gnome-online-accounts.enable = true;
    services.gnome3.gnome-keyring.enable = true;

    virtualisation.docker.enable = true;

    # Required for polybar docker script
    security.sudo.configFile = ''
      user ALL=(ALL) NOPASSWD: ${pkgs.docker}/bin/docker ps -qf status=running
    '';
  };
}
