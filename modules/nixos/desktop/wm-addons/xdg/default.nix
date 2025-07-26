{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.xdg;
  inherit (config._custom.globals) themeColors;
  mimeTypes = import ./mixins/mimeTypes.nix;
in {
  options._custom.desktop.xdg.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        xdg-launch
        desktop-file-utils
        xdg-user-dirs # Update user dirs as described in https://freedesktop.org/wiki/Software/xdg-user-dirs/
        xdg-user-dirs-gtk # Used to create the default bookmarks
      ];

      etc."mime.types".source = ./dotfiles/mime.types;

      shellAliases.open = "xdg-open";
      shellAliases.o = "xdg-open";

      pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
    };

    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    services.dbus.enable = lib.mkDefault true;
    xdg.portal.enable = true;
    # xdg.portal.xdgOpenUsePortal = true;

    xdg.icons.enable = true;

    xdg.terminal-exec.enable = true;

    _custom.hm = {
      xdg.enable = true;
      xdg.systemDirs.data = [ "/usr/share" "/usr/local/share" ];
      xdg.userDirs.enable = true;

      xdg.configFile."mimeapps.list".force = true;
      xdg.configFile."xdg-desktop-portal-wlr/config".text = ''
        [screencast]
        max_fps=30
        chooser_type=simple
        chooser_cmd=slurp -d -b "${themeColors.background}bf" -c "${themeColors.primary}" -F "Iosevka NF" -w 1 -f %o -or
      '';

      xdg.mimeApps = {
        enable = true;
        defaultApplications = with lib;
          with mimeTypes;
          mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
            # TODO: make nvim use kitty as terminal
            "kitty-open" = text ++ [ "text/*" ];
            "google-chrome" = html ++ web;
            "imv" = images;
            "mpv" = media;
            "org.gnome.FileRoller" = archives;
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
