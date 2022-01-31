{ config, lib, pkgs, ... }:

let enablePowerManagement = true;
in {
  config = {
    # inspiration: https://github.com/NixOS/nixpkgs/blob/2ddc335e6f32b875e14ad9610101325b306a0add/nixos/modules/services/x11/desktop-managers/xfce.nix
    environment.systemPackages = with pkgs.xfce // pkgs;
      [
        glib # for gsettings
        gtk3.out # gtk-update-icon-cache

        gnome.gnome-themes-extra
        gnome.adwaita-icon-theme
        hicolor-icon-theme
        tango-icon-theme
        xfce4-icon-theme

        desktop-file-utils
        shared-mime-info # for update-mime-database

        # For a polkit authentication agent
        polkit_gnome

        # Needed by Xfce's xinitrc script
        xdg-user-dirs # Update user dirs as described in https://freedesktop.org/wiki/Software/xdg-user-dirs/

        xfce.exo # Application library for Xfce
        xfce.garcon # Xfce menu support library
        xfce.libxfce4ui # Widgets library for Xfce
        xfce.xfconf # Simple client-server configuration storage and query system for Xfce

        xfce.xfce4-screenshooter
        xfce.xfce4-session
        xfce.xfce4-settings
        xfce.xfce4-terminal

        pavucontrol
      ] ++ lib.optional config.powerManagement.enable xfce4-power-manager;

    environment.pathsToLink = [
      "/share/xfce4"
      "/lib/xfce4"
      "/share/gtksourceview-3.0"
      "/share/gtksourceview-4.0"
    ];

    services.xserver.desktopManager.session = [{
      name = "xfce";
      desktopNames = [ "XFCE" ];
      bgSupport = true;
      start = ''
        ${pkgs.runtimeShell} ${pkgs.xfce.xfce4-session.xinitrc} &
        waitPID=$!
      '';
    }];

    services.xserver.updateDbusEnvironment = true;
    services.xserver.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

    # Enable helpful DBus services.
    services.udisks2.enable = true;
    security.polkit.enable = true;
    services.accounts-daemon.enable = true;
    services.upower.enable = enablePowerManagement;
    services.gnome.glib-networking.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;
    # TODO: support printer?
    services.xserver.libinput.enable =
      lib.mkDefault true; # used in xfce4-settings-manager

    # Enable default programs
    programs.dconf.enable = true;

    # Shell integration for VTE terminals
    programs.bash.vteIntegration = lib.mkDefault true;
    programs.zsh.vteIntegration = lib.mkDefault true;

    powerManagement.enable = enablePowerManagement;
  };
}

