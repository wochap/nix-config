{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {
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

        # Enable fractional scaling on gnome wayland
        "org/gnome/mutter" = {
          experimental-features = if isWayland then "['scale-monitor-framebuffer']" else "[]";
        };
      };

      # Edit home files
      xdg.enable = true;
      xdg.systemDirs.data = [
        "/usr/share"
        "/usr/local/share"
      ];

      home.sessionVariables = {
        NIXOS_CONFIG = "/home/${userName}/nix-config/devices/desktop.nix";
        VIDEO = "mpv";
      };

      # Setup dotfiles
      home.file = {
        ".config/sublime-text-3/Packages/User/Default (Linux).sublime-keymap".source = ./dotfiles/linux.sublime-keymap.json;
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
    };
  };
}
