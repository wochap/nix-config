{ config, lib, ... }:

let cfg = config._custom.desktop.dbus;
in {
  options._custom.desktop.dbus.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.dbus.enable = true;
    services.gnome.glib-networking.enable = true;
    services.udisks2.enable = true; # interact with disks
    services.hardware.bolt.enable = true; # Thunderbolt
    services.fwupd.enable = true; # allows applications to update firmware
    services.xserver.updateDbusEnvironment =
      true; # call dbus-update-activation-environment on login
  };
}
