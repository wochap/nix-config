{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
  isHidpi = config._isHidpi;
in {
  config = {
    environment.systemPackages = with pkgs; [ capitaine-cursors ];

    # Required by pinentry-gnome3
    services.dbus = {
      enable = true;
      packages = [ pkgs.gcr ];
    };

    home-manager.users.${userName} = {
      # TODO: move out
      # Open GTK inspector with Ctrl + Shift + D
      # GTK_DEBUG=interactive <app>
      dconf.settings = {
        "org/gtk/Settings/Debug" = { enable-inspector-keybinding = true; };
        # Disable horrible evolution calendar popup window
        # source: https://askubuntu.com/questions/1238826/turn-off-calendar-notifications-ubuntu-20-04
        "org/gnome/evolution-data-server/calendar" = {
          notify-with-tray = true;
        };

        # Enable fractional scaling on gnome wayland
        "org/gnome/mutter" = {
          experimental-features =
            if isWayland then "['scale-monitor-framebuffer']" else "[]";
        };
      };

      # Edit home files
      xdg.enable = true;
      xdg.systemDirs.data = [ "/usr/share" "/usr/local/share" ];

      home.sessionVariables = {
        NIXOS_CONFIG = "/home/${userName}/nix-config/devices/desktop.nix";
      };

      # Setup dotfiles
      xdg.configFile = {
        "sublime-text-3/Packages/User/Default (Linux).sublime-keymap".source =
          ./dotfiles/linux.sublime-keymap.json;
      };

      # home.file = {
      #   ".icons/default/icons".source = "${pkgs.numix-cursor-theme}/share/icons/Numix-Cursor/cursors";
      # };

      xsession.pointerCursor = {
        name = "capitaine-cursors";
        package = pkgs.capitaine-cursors;
        # 16, 32, 48 or 64
        size = if (isHidpi && isXorg) then 64 else 32;
      };
    };
  };
}
