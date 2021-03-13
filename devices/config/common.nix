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
  http-url-handler = pkgs.makeDesktopItem {
    name = "http-url-handler";
    desktopName = "HTTP URL handler";
    comment = "Open an HTTP/HTTPS URL with a particular browser";
    exec = "/etc/open_url.py %u";
    type = "Application";
    terminal = "false";
    extraEntries = ''
      TryExec=/etc/open_url.py
      X-MultipleArgs=false
      NoDisplay=true
      MimeType=x-scheme-handler/http;x-scheme-handler/https
    '';
  };
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
      etc = {
        "restart_goa_daemon.sh" = {
          source = ./scripts/restart_goa_daemon.sh;
          mode = "0755";
        };
        "open_url.py" = {
          source = ./scripts/open_url.py;
          mode = "0755";
        };
      };
      shellAliases = {
        open = "xdg-open";
        ll = "ls -l";
      };
      sessionVariables = lib.mkMerge [
        {
          CM_MAX_CLIPS = "30";
          CM_OWN_CLIPBOARD = "1";
          CM_SELECTIONS = "clipboard";
          ELECTRON_TRASH="trash-cli"; # fix vscode delete
          QT_AUTO_SCREEN_SCALE_FACTOR = "0";
          QT_FONT_DPI = "144";
          QT_QPA_PLATFORMTHEME = "qt5ct";
          QT_SCALE_FACTOR = "1.5";
          XCURSOR_SIZE = "40";
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
      direnv # auto run nix-shell
      dos2unix
      evtest
      ffmpeg-full # music/video codecs?
      fzf # fuzzy search
      git
      glib # gio
      gnumake # make
      inxi # check compositor running
      killall
      libqalculate
      manpages
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      trash-cli # required by vscode
      unzip
      vim
      wget
      wmctrl # perform actions on windows
      wmutils-core
      xclip # clipboard cli
      xdo # perform actions on windows
      xdotool # fake keyboard/mouse input
      xlayoutdisplay # fix dpi
      xorg.xdpyinfo # show monitor info
      xorg.xev # get key actual name
      xorg.xeyes # check if app is running on wayland
      xorg.xkbcomp
      zip

      # Apps CLI
      docker-compose
      feh # image viewer
      gotop # monitor system
      htop # monitor system
      neofetch # print computer info
      nvtop # monitor system nvidia
      radeontop # monitor system amd
      ranger # file manager cli
      screenfetch # show system info
      scrot # screen capture

      # IP Webcam related
      gnome3.zenity
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gstreamer
      gst_all_1.gstreamer.dev
      run-videochat
      v4l-utils

      # DE
      # pywal # theme color generator cli
      alttab # windows like alt + tab
      betterlockscreen # screen locker
      blueberry # bluetooth tray
      caffeine-ng
      clipmenu # clipboard manager
      hunspell # dictionary for document programs
      hunspellDicts.en-us
      kitty # terminal
      kmag # magnifying glass
      mpv # video player
      nitrogen # wallpaper manager
      pamixer # audio cli
      pavucontrol # audio settings gui
      playerctl # media player cli
      systemd
      # xzoom # magnifying glass
      # xmagnify # magnifying glass

      # Apps
      anki
      deluge # torrent client
      etcher # create booteable usbs
      filelight # view disk usage
      # gnome3.gnome-disk-utility
      # gnome3.gnome-system-monitor
      # gnome3.bijiben
      gnome3.cheese # test webcam
      gnome3.eog # image viewer
      gnome3.evolution
      gnome3.file-roller # archive manager
      gnome3.geary # email client
      gnome3.gnome-calculator
      gnome3.gnome-calendar
      gnome3.gnome-clocks
      gnome3.gnome-control-center # add google account for geary and calendar
      gnome3.gnome-font-viewer
      gnome3.gnome-sound-recorder # test microphone
      gnome3.gnome-system-monitor
      gnome3.gnome-todo
      gnome3.pomodoro
      gtimelog
      inkscape # photo editor cli/gui
      nomacs # image viewer/editor
      notejot # simple note app
      pick-colour-picker # color picker gui
      screenkey # show key pressed
      simplenote
      sublime3 # text editor
      xfce.exo
      xfce.thunar # file manager
      xfce.thunar-archive-plugin
      xfce.thunar-volman # auto mont devices
      xfce.xfconf # where thunar settings are saved
      zathura # PDF viewer
      zoom-us

      # Themes
      adwaita-qt
      capitaine-cursors
      gnome3.adwaita-icon-theme
      hicolor-icon-theme
      papirus-icon-theme

      # Themes settings
      gnome3.gsettings-desktop-schemas
      gtk-engine-murrine
      gtk_engines
      lxappearance
      qt5.qtgraphicaleffects
      qt5ct
    ] ++ [
      localPkgs.eww # custom widgets daemon
      localPkgs.sddm-sugar-dark-greeter
      localPkgs.sddm-whitesur-greeter
      localPkgs.whitesur-dark-icons
      localPkgs.zscroll # scroll text in shells
      http-url-handler
    ];

    fonts = {
      enableFontDir = true;
      enableGhostscriptFonts = true;
      enableDefaultFonts = true;
      fonts = with pkgs; [
        corefonts # basic fonts for office
        fira-code
        font-awesome
        font-awesome_4
        material-icons
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        open-sans
        roboto
        roboto-slab
        siji
        terminus_font

        # (lib.mkIf (!isMbp) nerdfonts) # requires nvidia?
        (nerdfonts.override {
          fonts = [
            "FiraCode"
            "FiraMono"
            "Hack"
            "Iosevka"
          ];
        })
      ] ;
      fontconfig = {
        allowBitmaps = true;
        defaultFonts = {
          serif = [ "Roboto Slab" ];
          sansSerif = [ "Roboto" ];
          monospace = [ "FiraCode Nerd Font Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    environment.pathsToLink = [
      "/share/zsh"

      # Links /libexec from derivations to /run/current-system/sw
      "/libexec"
    ];

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
      shell = pkgs.zsh;
      uid = 1000;
      password = "123456";
      home = "/home/gean";
      isNormalUser = true;
      extraGroups = [
        "audio"
        "disk"
        "docker"
        "networkmanager"
        "storage"
        "video"
        "wheel"
      ];
      openssh.authorizedKeys.keyFiles = [
        "~/.ssh/id_rsa.pub"
        "~/.ssh/id_rsa_boc.pub"
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
        allowedTCPPortRanges = [
          { from = 8080; to = 8090; }
          { from = 3000; to = 3010; }
        ];
        allowedTCPPorts = [
          3333
          8000
          80
          22
        ];
      };
    };

    # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
    programs.zsh.enable = true;
    programs.fish.enable = true;

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

    # Auto run nix-shell
    services.lorri.enable = true;

    # Setup keychron
    services.xserver = {
      layout = "us";
      xkbModel = "pc104";
      xkbVariant = "altgr-intl";
    };

    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    # Apply trim to SSDs
    services.fstrim.enable = true;

    # Required for gnome calendar and geary
    services.gnome3.evolution-data-server.enable = true;
    services.gnome3.gnome-online-accounts.enable = true;
    services.gnome3.gnome-keyring.enable = true;

    # Fix gnome-keyring when sddm is enabled
    security.pam.services.sddm.enableGnomeKeyring = true;

    # Change flatpak env vars https://github.com/flatpak/flatpak/issues/2980
    services.flatpak.enable = true;

    virtualisation.docker.enable = true;
    # virtualisation.anbox.enable = true;

    # Required for polybar docker script
    security.sudo.configFile = ''
      user ALL=(ALL) NOPASSWD: ${pkgs.docker}/bin/docker ps -qf status=running
    '';

    # consistent file dialog
    xdg.portal = {
      enable = true;
      gtkUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-kde
      ];
    };

    documentation.man.generateCaches = true;
    documentation.dev.enable = true;
  };
}
