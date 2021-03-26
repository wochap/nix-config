{ config, pkgs, lib, ... }:

let
  isHidpi = config._isHidpi;
  isMbp = config.networking.hostName == "gmbp";
  isWayland = config._displayServer == "wayland";
  isXorg = config._displayServer == "xorg";
in
{
  imports = [
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/pkgs-xorg.nix
    ./mixins/fonts.nix
    ./mixins/ipwebcam.nix
    ./mixins/nixos-networking.nix
    ./mixins/keychron.nix
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
          # Fix vscode delete
          ELECTRON_TRASH="trash-cli";

          QT_QPA_PLATFORMTHEME = "qt5ct";
        }
        (lib.mkIf isXorg {
          # Setup clipboard manager
          CM_MAX_CLIPS = "30";
          CM_OWN_CLIPBOARD = "1";
          CM_SELECTIONS = "clipboard";
        })
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

    # Links those paths from derivations to /run/current-system/sw
    environment.pathsToLink = [
      "/share/zsh"
      "/libexec"
    ];

    # Required by thunar
    # services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.gvfs.package = pkgs.xfce.gvfs;
    services.tumbler.enable = true;

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
