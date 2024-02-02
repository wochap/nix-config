{ config, lib, ... }:

let cfg = config._custom.wm.dbus;
in {
  options._custom.wm.dbus.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.dbus.enable = true;
    services.gnome.glib-networking.enable = true;
    services.udisks2.enable = true; # interact with disks
    services.hardware.bolt.enable = true; # Thunderbolt
    services.xserver.updateDbusEnvironment =
      true; # call dbus-update-activation-environment on login
  };
}
