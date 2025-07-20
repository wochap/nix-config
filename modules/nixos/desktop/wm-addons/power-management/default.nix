{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.power-management;
  inherit (config._custom.globals) configDirectory;
  inherit (config.boot.kernelPackages) cpupower;
  batty = pkgs.writeScriptBin "batty" (builtins.readFile ./scripts/batty.sh);
in {
  options._custom.desktop.power-management = {
    enable = lib.mkEnableOption { };
    cpupowerGuiArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    enableBatty = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cpupower-gui
      cpupower
      powertop # only use it to check current power usage
      batty
      # psensor # unmaintained
      lm_sensors
    ];

    # systemd service for suspense and resume commands
    powerManagement.enable = true;

    # required by others apps
    services.upower.enable = true;

    # required by cpupower-gui
    services.dbus.packages = [ pkgs.cpupower-gui ];
    systemd = {
      user.services.cpupower-gui-user =
        lib.mkIf (builtins.length cfg.cpupowerGuiArgs > 0) {
          description = "Apply cpupower-gui config at user login";
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.cpupower-gui}/bin/cpupower-gui ${
                lib.concatStringsSep " " cfg.cpupowerGuiArgs
              }";
          };
        };
      services.cpupower-gui-helper = {
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

    _custom.hm = {
      xdg.configFile."batty/config.yaml".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/config.yaml;

      systemd.user.services.batty = lib.mkIf cfg.enableBatty
        (lib._custom.mkWaylandService {
          Unit.Description = "A Customizable Battery Notifier Script";
          Service = {
            ExecStart = "${batty}/bin/batty";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        });
    };
  };
}
