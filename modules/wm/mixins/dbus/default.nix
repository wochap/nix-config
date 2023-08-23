{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.wm.dbus;
in {
  options._custom.wm.dbus = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        # For a polkit authentication agent
        polkit_gnome
      ];

    security.polkit.enable = true;
    services.dbus.enable = true;
    services.gnome.glib-networking.enable = true;
    services.udisks2.enable = true;
    services.hardware.bolt.enable = true; # Thunderbolt
    services.xserver.updateDbusEnvironment = true;
  };
}
