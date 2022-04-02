{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
  globals =
    import ../../../mixins/globals.nix { inherit config pkgs lib inputs; };
in {
  config = {
    environment.systemPackages = with pkgs; [ globals.cursor.package ];

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
      #   # Dracula-cursors doesn't support sizes
      #   ".icons/Dracula-cursors".source = "${inputs.dracula-gtk-theme}/kde/cursors/Dracula-cursors";
      # };

      xsession.pointerCursor = lib.mkIf (!isWayland) {
        name = globals.cursor.name;
        package = globals.cursor.package;
        size = globals.cursor.size;
      };
    };
  };
}
