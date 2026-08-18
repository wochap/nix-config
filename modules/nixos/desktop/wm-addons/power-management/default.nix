{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.power-management;
  inherit (config._custom.globals) configDirectory systemdTarget;
  inherit (config.boot.kernelPackages) cpupower;
  batty = pkgs.writeScriptBin "batty" (builtins.readFile ./scripts/batty.sh);
  legion-battery-conservation = pkgs.writeScriptBin "legion-battery-conservation" (
    builtins.readFile ./scripts/legion-battery-conservation.sh
  );
  legion-rapid-charging = pkgs.writeScriptBin "legion-rapid-charging" (
    builtins.readFile ./scripts/legion-rapid-charging.sh
  );
  legion-keyboard-autosuspend = pkgs.writeScriptBin "legion-keyboard-autosuspend" (
    builtins.readFile ./scripts/legion-keyboard-autosuspend.sh
  );
  legion-ec-monitor = pkgs.writeScriptBin "legion-ec-monitor" (
    builtins.readFile ./scripts/legion-ec-monitor.sh
  );
in
{
  options._custom.desktop.power-management = {
    enable = lib.mkEnableOption { };
    cpupowerGui = {
      enable = lib.mkEnableOption { };
      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
    enableBatty = lib.mkEnableOption { };
    # tune keyboard to prevent aggressive autosuspend
    keyboard = {
      enable = lib.mkEnableOption { };
      delayMs = lib.mkOption {
        type = lib.types.int;
        default = 15000;
      };
      idVendor = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      idProduct = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        powertop # only use it to check current power usage
        powerstat # power usage
        batty
        legion-battery-conservation
        legion-rapid-charging
        legion-keyboard-autosuspend
        legion-ec-monitor
        lm_sensors
        cpupower
      ];

      # conflicts with power-profiles-daemon
      services.tlp.enable = lib.mkDefault false;

      # conflicts with tlp
      services.power-profiles-daemon.enable = lib.mkDefault false;

      # systemd service for suspense and resume commands
      powerManagement.enable = true;

      # required by others apps
      services.upower.enable = true;

      # enable powertop auto tuning on startup
      services.udev.extraRules = lib.mkIf cfg.keyboard.enable ''
        # disable USB auto-suspend for keyboard controller
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${cfg.keyboard.idVendor}", ATTR{idProduct}=="${cfg.keyboard.idProduct}", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="${toString cfg.keyboard.delayMs}"
      '';
      powerManagement.powertop = {
        enable = lib.mkDefault true;
        # NOTE: ' after getExe tells nixos to install the package
        postStart = lib.mkIf cfg.keyboard.enable ''
          # retrigger the udev rule for the keyboard after powertop's auto-tune
          ${lib.getExe' config.systemd.package "udevadm"} trigger \
            --action=add \
            --subsystem-match=usb \
            --attr-match=idVendor=${cfg.keyboard.idVendor} \
            --attr-match=idProduct=${cfg.keyboard.idProduct}
        '';
      };

      # Make powertop non-blocking during boot by overriding the Type
      # Makes postStart run at the same time as powertop
      # systemd.services.powertop.serviceConfig.Type = lib.mkForce "simple";

      _custom.hm = lib.mkIf cfg.enableBatty {
        xdg.configFile."batty/config.yaml".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/config.yaml;

        systemd.user.services.batty = lib._custom.mkWaylandService {
          Unit.Description = "A Customizable Battery Notifier Script";
          Service = {
            ExecStart = "${batty}/bin/batty";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.cpupowerGui.enable) {
      environment.systemPackages = with pkgs; [
        cpupower-gui
      ];

      # select cpu profile
      # required by cpupower-gui
      services.dbus.packages = [ pkgs.cpupower-gui ];
      systemd = {
        sleep.settings.Sleep.HibernateDelaySec = "2h";
        user.services.cpupower-gui-user = lib.mkIf (builtins.length cfg.cpupowerGui.args > 0) {
          description = "Apply cpupower-gui config at user login";
          wantedBy = [ systemdTarget ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.cpupower-gui}/bin/cpupower-gui ${lib.concatStringsSep " " cfg.cpupowerGui.args}";
          };
        };
        services.cpupower-gui-helper = {
          description = "cpupower-gui system helper";
          aliases = [ "dbus-org.rnd2.cpupower_gui.helper.service" ];
          serviceConfig = {
            Type = "dbus";
            BusName = "org.rnd2.cpupower_gui.helper";
            ExecStart = "${pkgs.cpupower-gui}/lib/cpupower-gui/cpupower-gui-helper";
          };
        };
      };
    })
  ];
}
