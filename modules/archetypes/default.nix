{ config, lib, ... }:

{
  options._custom.archetypes.wm-wayland-desktop.enable = lib.mkEnableOption { };
  options._custom.archetypes.de-wayland-desktop.enable = lib.mkEnableOption { };

  config = lib.mkMerge [
    (lib.mkIf config._custom.archetypes.wm-wayland-desktop.enable {
      _custom.security.doas.enable = true;
      _custom.security.gnome-keyring.enable = true;
      _custom.security.gpg.enable = true;
      _custom.security.polkit.enable = true;
      _custom.security.ssh.enable = true;

      _custom.de.audio.enable = true;
      _custom.de.backlight.enable = true;
      _custom.de.bluetooth.enable = true;
      _custom.de.calendar.enable = true;
      _custom.de.cursor.enable = true;
      _custom.de.dbus.enable = true;
      _custom.de.email.enable = true;
      _custom.de.fonts.enable = true;
      _custom.de.gtk.enable = true;
      _custom.de.logind.enable = true;
      _custom.de.music.enable = true;
      _custom.de.neofetch.enable = true;
      _custom.de.networking.enable = true;
      _custom.de.plymouth.enable = true;
      _custom.de.power-management.enable = true;
      _custom.de.power-management.enableLowBatteryNotification = true;
      _custom.de.qt.enable = true;
      _custom.de.xdg.enable = true;

      _custom.de.cliphist.enable = true;
      _custom.de.dunst.enable = true;
      _custom.de.gammastep.enable = true;
      _custom.de.kanshi.enable = true;
      _custom.de.swayidle.enable = true;
      _custom.de.swaylock.enable = true;
      _custom.de.swww.enable = true;
      _custom.de.tofi.enable = true;
      _custom.de.utils.enable = true;
      _custom.de.waybar.enable = true;
      _custom.de.wayland-session.enable = true;
      _custom.de.wob.enable = true;

      _custom.de.greetd.enable = true;
    })

    (lib.mkIf config._custom.archetypes.de-wayland-desktop.enable {
      _custom.security.doas.enable = true;
      _custom.security.gpg.enable = true;
      _custom.security.ssh.enable = true;

      _custom.de.fonts.enable = true;
      _custom.de.neofetch.enable = true;
      _custom.de.networking.enable = true;
      # _custom.de.plymouth.enable = true;
      _custom.de.power-management.enable = true;

      _custom.de.utils.enable = true;
    })
  ];
}
