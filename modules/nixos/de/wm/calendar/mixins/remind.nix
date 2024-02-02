{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.calendar;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome configHome;
  remFilePath = "${configHome}/remind/remind.rem";
  remindScript = pkgs.writeShellScript "remind" ''
    ${pkgs.remind}/bin/remind -z -k'${pkgs.dunst}/bin/dunstify --appname "Remind" -i "kalarm" "Reminder" "%s" &' ${remFilePath}
  '';
  ics2remScript = pkgs.writeShellScript "ics2rem" ''
    ${pkgs.findutils}/bin/find ${dataHome}/vdirsyncer -name '*.ics' -exec ics2rem {} \; | LC_ALL=C ${pkgs.coreutils-full}/bin/sort -k2,2M -k3,3n > ${remFilePath}
    ${pkgs.coreutils-full}/bin/echo "ics2rem finished"
  '';
in {
  config = lib.mkIf cfg.enable {

    _custom.hm = {
      home.packages = with pkgs; [ remind ];

      systemd.user.services.ics2rem = {
        Unit = {
          Description = "Convert ics files to rem";
          After = [ "vdirsyncer.service" ];
        };

        Service = {
          Type = "oneshot";
          PassEnvironment = [ "PATH" ];
          ExecStart = "${ics2remScript}";
        };

        Install = { WantedBy = [ "vdirsyncer.service" ]; };
      };

      systemd.user.services.remind = {
        Unit = {
          Description = "Remind is a sophisticated calendar and alarm program.";
          Documentation = "https://dianne.skoll.ca/projects/remind/";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          PassEnvironment = [ "PATH" ];
          ExecStart = "${remindScript}";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
