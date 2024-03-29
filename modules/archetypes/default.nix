{ config, lib, ... }:

{
  options._custom.archetypes.wm-wayland-desktop.enable = lib.mkEnableOption { };
  options._custom.archetypes.wm-xorg-desktop.enable = lib.mkEnableOption { };
  options._custom.archetypes.de-wayland-desktop.enable = lib.mkEnableOption { };
  options._custom.archetypes.gnome.enable = lib.mkEnableOption { };
  options._custom.archetypes.kde.enable = lib.mkEnableOption { };

  config = lib.mkMerge [
    (lib.mkIf config._custom.archetypes.wm-wayland-desktop.enable {
      _custom.security.doas.enable = true;
      _custom.security.gnome-keyring.enable = true;
      _custom.security.gpg.enable = true;
      _custom.security.polkit.enable = true;
      _custom.security.ssh.enable = true;

      _custom.desktop.audio.enable = true;
      _custom.desktop.backlight.enable = true;
      _custom.desktop.bluetooth.enable = true;
      _custom.desktop.calendar.enable = true;
      _custom.desktop.cursor.enable = true;
      _custom.desktop.dbus.enable = true;
      _custom.desktop.email.enable = true;
      _custom.desktop.fonts.enable = true;
      _custom.desktop.gtk.enable = true;
      _custom.desktop.gtk.enableCsd = false;
      _custom.desktop.logind.enable = true;
      _custom.desktop.music.enable = true;
      _custom.desktop.neofetch.enable = true;
      _custom.desktop.networking.enable = true;
      _custom.desktop.plymouth.enable = true;
      _custom.desktop.power-management.enable = true;
      _custom.desktop.power-management.enableLowBatteryNotification = true;
      _custom.desktop.qt.enable = true;
      _custom.desktop.xdg.enable = true;
      _custom.desktop.xwaylandvideobridge.enable = true;

      _custom.desktop.ags.enable = true;
      _custom.desktop.cliphist.enable = true;
      _custom.desktop.dunst.enable = true;
      _custom.desktop.electron-support.enable = true;
      _custom.desktop.gammastep.enable = true;
      _custom.desktop.kanshi.enable = true;
      _custom.desktop.swayidle.enable = lib.mkDefault true;
      _custom.desktop.swaylock.enable = true;
      _custom.desktop.swww.enable = true;
      _custom.desktop.tofi.enable = true;
      _custom.desktop.waybar.enable = lib.mkDefault true;
      _custom.desktop.waybar.systemdEnable = lib.mkDefault true;
      _custom.desktop.wayland-session.enable = true;
      _custom.desktop.wayland-utils.enable = true;
      _custom.desktop.ydotool.enable = lib.mkDefault true;

      _custom.desktop.greetd.enable = lib.mkDefault true;
    })

    (lib.mkIf config._custom.archetypes.wm-xorg-desktop.enable {
      _custom.security.doas.enable = true;
      _custom.security.gnome-keyring.enable = true;
      _custom.security.gpg.enable = true;
      _custom.security.polkit.enable = true;
      _custom.security.ssh.enable = true;

      _custom.desktop.audio.enable = true;
      _custom.desktop.backlight.enable = true;
      _custom.desktop.bluetooth.enable = true;
      _custom.desktop.calendar.enable = true;
      _custom.desktop.cursor.enable = true;
      _custom.desktop.dbus.enable = true;
      _custom.desktop.email.enable = true;
      _custom.desktop.fonts.enable = true;
      _custom.desktop.gtk.enable = true;
      _custom.desktop.gtk.enableCsd = false;
      _custom.desktop.logind.enable = true;
      _custom.desktop.music.enable = true;
      _custom.desktop.neofetch.enable = true;
      _custom.desktop.networking.enable = true;
      _custom.desktop.plymouth.enable = true;
      _custom.desktop.power-management.enable = true;
      _custom.desktop.power-management.enableLowBatteryNotification = true;
      _custom.desktop.qt.enable = true;
      _custom.desktop.xdg.enable = true;

      _custom.desktop.dunst.enable = true;
      _custom.desktop.gammastep.enable = true;

      _custom.desktop.tint2.enable = true;
      _custom.desktop.xorg-session.enable = true;
      _custom.desktop.xorg-utils.enable = true;
      _custom.desktop.xsettingsd.enable = true;

      _custom.desktop.greetd.enable = lib.mkDefault true;
    })

    (lib.mkIf config._custom.archetypes.de-wayland-desktop.enable {
      _custom.security.doas.enable = true;
      _custom.security.gpg.enable = true;
      _custom.security.ssh.enable = true;

      _custom.desktop.fonts.enable = true;
      _custom.desktop.gtk.enable = true;
      _custom.desktop.gtk.enableCsd = true;
      _custom.desktop.neofetch.enable = true;
      _custom.desktop.networking.enable = true;
      _custom.desktop.plymouth.enable = true;
      _custom.desktop.power-management.enable = true;

      _custom.desktop.electron-support.enable = true;
      _custom.desktop.wayland-utils.enable = true;
    })

    (lib.mkIf config._custom.archetypes.gnome.enable {
      _custom.archetypes.de-wayland-desktop.enable = true;

      _custom.security.gnome-keyring.enable = true;

      _custom.desktop.gnome.enable = lib.mkForce true;
    })

    (lib.mkIf config._custom.archetypes.kde.enable {
      _custom.archetypes.de-wayland-desktop.enable = true;

      _custom.desktop.audio.enable = true;
      _custom.desktop.bluetooth.enable = true;

      _custom.desktop.kde.enable = lib.mkForce true;
    })
  ];
}
