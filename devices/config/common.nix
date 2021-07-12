{ config, pkgs, lib, ... }:

let
  isHidpi = config._isHidpi;
in
{
  imports = [
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/pkgs-xorg.nix
    ./mixins/fonts.nix
    ./mixins/ipwebcam
    ./mixins/nixos-networking.nix
    ./mixins/keychron.nix
    ./mixins/apps-gnome.nix
    ./mixins/apps-xfce.nix
    ./mixins/docker.nix
    ./mixins/lorri.nix
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

      #Enable ntfs
      supportedFilesystems = [ "ntfs" ];
    };

    environment = {
      etc = {
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
        (lib.mkIf isHidpi {
          QT_AUTO_SCREEN_SCALE_FACTOR = "0";
          QT_FONT_DPI = "144";
          QT_SCALE_FACTOR = "1.5";
        })
      ];

      # Links those paths from derivations to /run/current-system/sw
      pathsToLink = [
        "/libexec"
      ];
    };

    # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
    programs.zsh.enable = true;
    programs.fish.enable = true;

    # Remember private keys
    programs.ssh.startAgent = true;

    # Change flatpak env vars https://github.com/flatpak/flatpak/issues/2980
    # services.flatpak.enable = true;

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
