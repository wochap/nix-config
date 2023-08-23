{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.wm.xdg;
  userName = config._userName;
  mimeTypes = import ./mixins/mimeTypes.nix;
in {
  options._custom.wm.xdg = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        desktop-file-utils
        xdg-user-dirs # Update user dirs as described in https://freedesktop.org/wiki/Software/xdg-user-dirs/
      ];

      shellAliases = { open = "xdg-open"; };
    };

    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    # NOTE: it required dbus, also setup extraPortals according to your wm
    xdg.portal.enable = true;
    # xdg.portal.xdgOpenUsePortal = true;

    xdg.icons.enable = true;

    xdg.mime = {
      enable = true;
      defaultApplications = with lib;
        with mimeTypes;
        mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
          "thunar" = dirs;
          "nvim" = text;
          "google-chrome" = html;
          "imv" = images;
          "mpv" = media;
          "org.gnome.Fileroller" = archives;
        });
      addedAssociations = with lib;
        with mimeTypes;
        mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
          firefox = dirs ++ text ++ images ++ media;
        });
    };

    home-manager.users.${userName} = {
      # Edit home files
      xdg.enable = true;
      xdg.systemDirs.data = [ "/usr/share" "/usr/local/share" ];

      xdg.configFile."mimeapps.list".force = true;

      xdg.mimeApps = {
        enable = true;
        defaultApplications = with lib;
          with mimeTypes;
          mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
            "amfora" = [ "x-scheme-handler/gemini" ];
            "Postman" = [ "x-scheme-handler/postman" ];
            # "neomutt" = [
            #   "message/rfc822"
            #   "x-scheme-handler/mailto"
            # ];
            # "newsboat" = [
            #   "x-scheme-handler/news"
            #   "x-scheme-handler/rss+xml"
            #   "x-scheme-handler/x-extension-rss"
            #   "x-scheme-handler/feed"
            # ];
            # transmission-gtk =
            #   [ "application/x-bittorrent" "x-scheme-handler/magnet" ];
          });
      };
    };
  };
}
