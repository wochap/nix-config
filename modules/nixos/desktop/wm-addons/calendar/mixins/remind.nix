{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.calendar;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome configHome;
  remFilePath = "${configHome}/remind/remind.rem";
  remindScript = pkgs.writeShellScript "remind" ''
    ${pkgs.remind}/bin/remind -z -k'${pkgs.libnotify}/bin/notify-send --app-name=Remind --icon=kalarm "Reminder" "%s" &' ${remFilePath}
  '';
  python-remind-final = pkgs._custom.pythonPackages.python-remind;
  ics2remScript = pkgs.writeShellScript "ics2rem" ''
    ${pkgs.coreutils-full}/bin/echo "ics2rem start"
    ${pkgs.findutils}/bin/find ${dataHome}/vdirsyncer -name '*.ics' -exec ${python-remind-final}/bin/ics2rem {} \; | LC_ALL=C ${pkgs.coreutils-full}/bin/sort -k2,2M -k3,3n > ${remFilePath}
    ${pkgs.coreutils-full}/bin/echo "ics2rem finished"
  '';
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        remind
        python-remind-final # ics2rem
      ];

      xdg.configFile."remind/.keep".text = "";

      systemd.user.services.ics2rem = {
        Unit = {
          Description = "Convert ics files to rem";
          After = [ "vdirsyncer.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${ics2remScript}";
        };
        Install.WantedBy = [ "vdirsyncer.service" ];
      };

      # TODO: change service target
      systemd.user.services.remind = lib._custom.mkWaylandService {
        Unit = {
          Description = "Remind is a sophisticated calendar and alarm program.";
          Documentation = "https://dianne.skoll.ca/projects/remind/";
        };
        Service = {
          ExecStart = "${remindScript}";
          KillMode = "mixed";
        };
      };
    };
  };
}
