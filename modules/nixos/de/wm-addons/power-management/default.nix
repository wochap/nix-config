{ config, pkgs, lib, ... }:

let
  inherit (config.boot.kernelPackages) cpupower;
  cfg = config._custom.de.power-management;
  battery-notification = pkgs.writeScriptBin "battery-notification"
    (builtins.readFile ./scripts/battery-notification.sh);
in {
  options._custom.de.power-management = {
    enable = lib.mkEnableOption { };
    enableLowBatteryNotification = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cpupower-gui
      cpupower
      powertop # only use it to check current power usage
      battery-notification
    ];

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

    _custom.hm.systemd.user.services.battery-notification =
      lib.mkIf cfg.enableLowBatteryNotification (lib._custom.mkWaylandService {
        Unit.Description =
          "A script that shows warning messages to the user when the battery is almost empty.";
        Unit.Documentation = "https://github.com/rjekker/i3-battery-popup";
        Service = {
          PassEnvironment = [ "PATH" "DISPLAY" ];
          ExecStart = "battery-notification -t 5s -L 15 -l 5 -n -i battery -D";
          Restart = "on-failure";
          KillMode = "mixed";
        };
      });
  };
}
