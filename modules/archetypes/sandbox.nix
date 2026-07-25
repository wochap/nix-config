{
  config,
  lib,
  pkgs,
  ...
}:

{
  options._custom.archetypes.sandbox.enable = lib.mkEnableOption { };

  config = lib.mkIf config._custom.archetypes.sandbox.enable {
    _custom.home-manager.enable = true;
    _custom.nix.enable = true;
    _custom.globals.enable = true;

    _custom.security.apparmor.enable = true;
    _custom.security.doas.enable = true;
    _custom.security.doas.requirePassword = true;
    # _custom.security.gnome-keyring.enable = lib.mkDefault true;
    _custom.security.gpg.enable = true;
    # _custom.security.kwallet.enable = lib.mkDefault false;
    # _custom.security.network.enable = true;
    # _custom.security.pam.enable = true;
    # _custom.security.polkit.enable = true;
    _custom.security.ssh.enable = true;

    # _custom.system.console.enable = true;
    _custom.system.fhs-compat.enable = true;
    _custom.system.others.enable = true;
    # _custom.system.windows.enable = lib.mkDefault true;
    # _custom.system.windows.enableSamba = lib.mkDefault true;
    _custom.system.internationalization.enable = true;
    _custom.system.user.enable = true;

    # _custom.desktop.audio.enable = true;
    # _custom.desktop.backlight.enable = true;
    # _custom.desktop.bluetooth.enable = true;
    # _custom.desktop.calendar.enable = true;
    _custom.desktop.cursor.enable = true;
    # _custom.desktop.dbus.enable = true;
    # _custom.desktop.email.enable = true;
    # _custom.desktop.fastfetch.enable = true;
    _custom.desktop.fonts.enable = true;
    _custom.desktop.gtk.enable = true;
    _custom.desktop.gtk.enableCsd = false;
    _custom.desktop.gtk.enableTheme = true;
    _custom.desktop.gtk.enableLibadwaitaWithoutAdwaita = true;
    # _custom.desktop.logind.enable = true;
    # _custom.desktop.mouseless.enable = lib.mkDefault false;
    # _custom.desktop.music.enable = true;
    _custom.desktop.networking.enable = true;
    # _custom.desktop.plymouth.enable = lib.mkDefault true;
    # _custom.desktop.power-management.enable = true;
    _custom.desktop.qt.enable = true;
    _custom.desktop.qt.enableTheme = true;
    _custom.desktop.qt.enableQt6ctKde = lib.mkDefault true;
    _custom.desktop.qt.enableQt5Integration = lib.mkDefault true;
    _custom.desktop.xdg.enable = true;
    # _custom.desktop.xwaylandvideobridge.enable = lib.mkDefault true;

    # _custom.desktop.cliphist.enable = true;
    _custom.desktop.electron-support.enable = true;
    # _custom.desktop.hyprlock.enable = lib.mkDefault true;
    # _custom.desktop.hyprsunset.enable = lib.mkDefault false;
    # _custom.desktop.kanshi.enable = true;
    # _custom.desktop.quickshell.enable = lib.mkDefault true;
    # _custom.desktop.idle.enable = lib.mkDefault true;
    # _custom.desktop.awww.enable = true;
    # _custom.desktop.tofi.enable = true;
    # _custom.desktop.uwsm.enable = true;
    _custom.desktop.wayland-session.enable = true;
    _custom.desktop.wayland-utils.enable = true;
    # _custom.desktop.wluma.enable = lib.mkDefault false;
    # _custom.desktop.ydotool.enable = lib.mkDefault true;

    # _custom.desktop.greetd.enable = lib.mkDefault true;

    _custom.headless-server.enable = true;
  };
}
