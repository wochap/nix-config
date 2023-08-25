{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/audio
    ./mixins/backlight
    ./mixins/bluetooth
    ./mixins/calendar
    ./mixins/cursor
    ./mixins/dbus
    ./mixins/greetd
    ./mixins/gtk
    ./mixins/networking
    ./mixins/power-management
    ./mixins/qt
    ./mixins/xdg
  ];
}
