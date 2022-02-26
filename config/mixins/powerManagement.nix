{ config, pkgs, lib, ... }:

let cpupower = config.boot.kernelPackages.cpupower;
in {
  config = {
    environment.systemPackages = with pkgs; [
      cpupower-gui
      cpupower

      lm_sensors
    ];

    # required by lm_sensors
    boot.kernelModules = [ "coretemp" ];

    powerManagement = {
      enable = true;

      # TODO: refactor to module options
      cpuFreqGovernor = "performance";
      cpufreq.min = 800000;
      # cpufreq.max = 3000000;
    };

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
