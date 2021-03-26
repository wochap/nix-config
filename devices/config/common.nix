{ config, pkgs, lib, ... }:

let
  isHidpi = config._isHidpi;
  isMbp = config.networking.hostName == "gmbp";
  isWayland = config._displayServer == "wayland";
  localPkgs = import ./packages { pkgs = pkgs; };
  run-videochat = pkgs.writeScriptBin "run-videochat" (builtins.readFile ./scripts/run-videochat.sh);
in
{
  imports = [
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/pkgs-xorg.nix
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

    environment.systemPackages = with pkgs; [
      # IP Webcam related
      gnome3.zenity
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gstreamer
      gst_all_1.gstreamer.dev
      run-videochat
      v4l-utils
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
  };
}
