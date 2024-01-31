{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.xdg;
  mimeTypes = import ./mixins/mimeTypes.nix;
in {
  options._custom.wm.xdg = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        desktop-file-utils
        xdg-user-dirs # Update user dirs as described in https://freedesktop.org/wiki/Software/xdg-user-dirs/
      ];

      etc."mime.types".source = ./dotfiles/mime.types;

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
    xdg.portal.config.common.default = "*";
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
          "kitty" = [ "application/x-shellscript" ];
        });
      addedAssociations = with lib;
        with mimeTypes;
        mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
          firefox = dirs ++ text ++ images ++ media;
        });
    };

    _custom.hm = {
      # Edit home files
      xdg.enable = true;
      xdg.systemDirs.data = [ "/usr/share" "/usr/local/share" ];
      xdg.userDirs.enable = true;

      xdg.configFile."mimeapps.list".force = true;
      xdg.configFile."xdg-desktop-portal-wlr/config".text = ''
        [screencast]
        max_fps=30
        chooser_type=simple
        chooser_cmd=slurp -f %o -or
      '';

      xdg.mimeApps = {
        enable = true;
        defaultApplications = with lib;
          with mimeTypes;
          mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
            "thunar" = dirs;
            # TODO: make nvim use kitty as terminal
            "kitty-open" = text;
            "google-chrome" = html;
            "imv" = images;
            "mpv" = media;
            "org.gnome.Fileroller" = archives;
            "kitty" = [ "application/x-shellscript" ];

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
