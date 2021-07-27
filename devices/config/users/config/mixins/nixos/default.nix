{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    home-manager.users.gean = {
      # TODO: move out
      # Open GTK inspector with Ctrl + Shift + D
      # GTK_DEBUG=interactive <app>
      dconf.settings = {
        "org/gtk/Settings/Debug" = {
          enable-inspector-keybinding = true;
        };
        # Disable horrible evolution calendar popup window
        # source: https://askubuntu.com/questions/1238826/turn-off-calendar-notifications-ubuntu-20-04
        "org/gnome/evolution-data-server/calendar" = {
          notify-with-tray = true;
        };
      };

      # Edit home files
      xdg.enable = true;
      xdg.systemDirs.data = [
        "/usr/share"
        "/usr/local/share"
      ];

      home.extraProfileCommands = ''
        if [[ -d "$out/share/applications" ]] ; then
          ${pkgs.desktop-file-utils}/bin/update-desktop-database $out/share/applications
        fi
      '';

      home.sessionVariables = {
        NIXOS_CONFIG = "/home/gean/nix-config/devices/desktop.nix";
        READER = "zathura";
        VIDEO = "mpv";
      };

      # Setup dotfiles
      home.file = {
        ".config/sublime-text-3/Packages/User/Default (Linux).sublime-keymap".source = ./dotfiles/linux.sublime-keymap.json;
        ".config/zathura/zathurarc".source = ./dotfiles/zathurarc;
        ".config/mpv/mpv.conf".source = ./dotfiles/mpv.conf;
        ".config/Thunar/uca.xml".source = ./dotfiles/Thunar/uca.xml;
      };

      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        defaultCacheTtl = 1800;
        pinentryFlavor = "gnome3";
      };

      services.redshift = {
        enable = true;
        package = if isWayland then pkgs.redshift-wlr else pkgs.redshift;
        latitude = "-12.051408";
        longitude = "-76.922124";
        temperature = {
          day = 4000;
          night = 3700;
        };
      };
    };
  };
}
