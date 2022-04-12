{ config, pkgs, lib, ... }:

let cpupower = config.boot.kernelPackages.cpupower;
in {
  config = {
    environment.systemPackages = with pkgs; [ cpupower-gui cpupower ];

    # required by others apps
    services.upower.enable = true;

    # required by cpupower-gui
    services.dbus.packages = [ pkgs.cpupower-gui ];
    systemd.services = {
      cpupower-gui-helper = {
        description = "cpupower-gui system helper";
        aliases = [ "dbus-org.rnd2.cpupower_gui.helper.service" ];
        serviceConfig = {
          Type = "dbus";
          BusName = "org.rnd2.cpupower_gui.helper";
          ExecStart =
            "${pkgs.cpupower-gui}/lib/cpupower-gui/cpupower-gui-helper";
        };
      };
    };
  };
}
