{ config, pkgs, lib, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "22f6736e628958f05222ddaadd7df7818fe8f59d";
    ref = "release-20.09";
  };
  isHidpi = config._isHidpi;
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
    _isHidpi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Flag for hidpi displays.";
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
        "nouveau.modeset=0"

        # Fix fn keys keychron
        "hid_apple.fnmode=0"
      ];
      kernelModules = [
        # Fix fn keys keychron
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
      font = if isHidpi then "latarcyrheb-sun32" else "Lat2-Terminus16";
      earlySetup = true;

      # TODO: make keyMap customizable
      keyMap = "us";

      packages = [
        pkgs.kbdKeymaps.dvp
        pkgs.kbdKeymaps.neo
        pkgs.terminus_font
      ];
    };

    environment = {
      etc = {
        "restart_goa_daemon.sh" = {
          source = ./scripts/restart_goa_daemon.sh;
          mode = "0755";
        };
        "open_url.sh" = {
          source = ./scripts/open_url.sh;
          mode = "0755";
        };
      };
      shellAliases = {
        gc = "git clone";
        glo = "git pull origin";
        gpo = "git push origin";
        ll = "ls -l";
        open = "xdg-open";
      };
      sessionVariables = lib.mkMerge [
        {
          # Setup clipboard manager
          CM_MAX_CLIPS = "30";
          CM_OWN_CLIPBOARD = "1";
          CM_SELECTIONS = "clipboard";

          # Fix vscode delete
          ELECTRON_TRASH="trash-cli";

          QT_QPA_PLATFORMTHEME = "qt5ct";
        }
        (lib.mkIf isWayland {
          # Force GTK to use wayland
          GDK_BACKEND = "wayland";
          CLUTTER_BACKEND = "wayland";

          # Force firefox to use wayland
          MOZ_ENABLE_WAYLAND = "1";
        })
        (lib.mkIf isHidpi {
          QT_AUTO_SCREEN_SCALE_FACTOR = "0";
          QT_FONT_DPI = "144";
          QT_SCALE_FACTOR = "1.5";
          XCURSOR_SIZE = "40";
        })
      ];
    };

    # List packages installed in system profile.
    # TODO: remove xorg packages if wayland is enabled
    environment.systemPackages = with pkgs; [
      # Tools
      # base-devel
      bc # calculator cli
      dex # execute DesktopEntry files
      direnv # auto run nix-shell
      dos2unix
      evtest
      ffmpeg-full # music/video codecs?
      fzf # fuzzy search
      git
      glib # gio
      glxinfo
      gnumake # make
      inxi # check compositor running
      killall
      libqalculate
      libva-utils # verifying VA-API
      manpages
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      trash-cli # required by vscode
      unzip
      vdpauinfo # verifying VDPAU
      vim
      wget
      wmctrl # perform actions on windows
      wmutils-core
      xautomation # simulate key press
      xclip # clipboard cli
      xdo # perform actions on windows
      xdotool # fake keyboard/mouse input
      xlayoutdisplay # fix dpi
      xorg.xdpyinfo # show monitor info
      xorg.xev # get key actual name
      xorg.xeyes # check if app is running on wayland
      xorg.xkbcomp # print keymap
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
      alacritty # terminal
      alttab # windows like alt + tab
      arandr # xrandr gui
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
      tmux # terminal multiplexer
      ulauncher
      # xzoom # magnifying glass
      # xmagnify # magnifying glass

      # Apps
      anki # mnemonic tool
      deluge # torrent client
      discord
      etcher # create booteable usbs
      filelight # view disk usage
      # gnome3.gnome-disk-utility
      # gnome3.gnome-system-monitor
      # gnome3.bijiben
      gnome3.cheese # test webcam
      gnome3.eog # image viewer
      gnome3.evolution # email/calendar client
      gnome3.file-roller # archive manager
      gnome3.geary # email client
      gnome3.gnome-calculator
      gnome3.gnome-calendar
      gnome3.gnome-clocks
      gnome3.gnome-control-center # add google account for gnome apps
      gnome3.gnome-font-viewer
      gnome3.gnome-sound-recorder # test microphone
      gnome3.gnome-system-monitor
      gnome3.gnome-todo
      gnome3.pomodoro
      gtimelog
      inkscape # photo editor cli/gui
      nomacs # image viewer/editor
      pick-colour-picker # color picker gui
      screenkey # show key pressed
      simplenote
      sublime3 # text editor
      xfce.exo
      (xfce.thunar.override {
        thunarPlugins = [
          xfce.thunar-archive-plugin
        ];
      })
      xfce.thunar # file manager
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
      qt5.qtgraphicaleffects # required by gddm themes
      qt5ct
    ] ++ [
      localPkgs.eww # custom widgets daemon
      localPkgs.http-url-handler
      localPkgs.sddm-sugar-dark-greeter
      localPkgs.sddm-whitesur-greeter
      localPkgs.stremio
      localPkgs.whitesur-dark-icons
      localPkgs.zscroll # scroll text in shells
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
      ];
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

    # Links those paths from derivations to /run/current-system/sw
    environment.pathsToLink = [
      "/share/zsh"
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
    # services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.gvfs.package = pkgs.xfce.gvfs;
    services.tumbler.enable = true;

    # Enable network manager
    networking = {
      enableIPv6 = false;
      wireless.enable = false;
      networkmanager.enable = true;
      nameservers = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
      ];
      firewall = {
        enable = true;
        allowedTCPPortRanges = [
          { from = 8080; to = 8090; }
          { from = 3000; to = 3010; }
        ];
        allowedTCPPorts = [
          # 20 # FTP (File Transfer Protocol)
          # 22 # Secure Shell (SSH)
          # 25 # Simple Mail Transfer Protocol (SMTP)
          # 53 #  Domain Name System (DNS)
          80 # Hypertext Transfer Protocol (HTTP)
          # 110 # Post Office Protocol (POP3)
          # 143 # Internet Message Access Protocol (IMAP)
          # 443 #  HTTP Secure (HTTPS)

          3333
          8000
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

    # Enable OpenGL
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;
    # Hardware video acceleration
    hardware.opengl.extraPackages = with pkgs; [
      libvdpau
      vaapiVdpau
      libvdpau-va-gl
    ];
    hardware.opengl.driSupport32Bit = !isMbp;

    # Enable audio
    sound.enable = true;
    hardware.pulseaudio.enable = true;
    # hardware.pulseaudio.support32Bit = true;

    # Auto run nix-shell
    services.lorri.enable = true;

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
    # services.flatpak.enable = true;

    virtualisation.docker.enable = true;
    # virtualisation.anbox.enable = true;

    # Required for polybar `docker module` script
    security.sudo.configFile = ''
      user ALL=(ALL) NOPASSWD: ${pkgs.docker}/bin/docker ps -qf status=running
    '';

    # Consistent file dialog
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
