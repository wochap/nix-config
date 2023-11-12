{ config, pkgs, lib, ... }:

let
  inherit (config.boot.kernelPackages) cpupower;
  cfg = config._custom.wm.power-management;
in {
  options._custom.wm.power-management = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cpupower-gui cpupower ];

    # systemd service for suspense and resume commands
    powerManagement.enable = true;

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
