{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.calendar;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome configHome stateHome;
  remFilePath = "${configHome}/remind/remind.rem";
  # regenerated from the synced ics files after every vdirsyncer sync
  genRemFile = "${configHome}/remind/calendar-generated.rem";
  # user-managed file for hand-written reminders (see README)
  manualRemFile = "${configHome}/remind/manual.rem";
  # epoch of the last successful remind-catchup run
  catchupStateFile = "${stateHome}/remind/last-check";

  remindScript = pkgs.writeShellScript "remind" ''
    ${pkgs.remind}/bin/remind -z -k'${pkgs.libnotify}/bin/notify-send --app-name=Remind --app-icon=kalarm --icon=kalarm --hint=int:transient:1 "Reminder" "%s" &' ${remFilePath}
  '';

  python-remind-final = pkgs._custom.pythonPackages.python-remind;
  # --posttime: timed events additionally notify cfg.preAlert (default 15
  # minutes) before start (remind always notifies at the event start too)
  ics2remScript = pkgs.writeShellScript "ics2rem" ''
    ${pkgs.coreutils-full}/bin/echo "ics2rem start"
    ${pkgs.coreutils}/bin/mkdir -p ${configHome}/remind
    ${pkgs.findutils}/bin/find ${dataHome}/vdirsyncer -name '*.ics' -exec ${python-remind-final}/bin/ics2rem --posttime "${cfg.preAlert}" {} \; | LC_ALL=C ${pkgs.coreutils-full}/bin/sort -k2,2M -k3,3n > "${genRemFile}.tmp"
    # atomic replace so the running remind daemon never reads a partial file
    ${pkgs.coreutils}/bin/mv -f "${genRemFile}.tmp" "${genRemFile}"
    ${pkgs.coreutils-full}/bin/echo "ics2rem finished"
  '';

  catchupScript = pkgs.writeShellScript "remind-catchup" ''
    exec ${pkgs.python3}/bin/python3 ${./remind_catchup.py} \
      ${pkgs.remind}/bin/remind \
      ${pkgs.libnotify}/bin/notify-send \
      ${remFilePath} \
      ${catchupStateFile}
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.accounts != { }) {
    _custom.hm = {
      home.packages = with pkgs; [
        remind
        python-remind-final # ics2rem
      ];

      # the daemon reads this file; generated and manual reminders are INCLUDEd
      xdg.configFile."remind/remind.rem".text = ''
        # This file is managed, put your own reminders into ${manualRemFile}.
        INCLUDE ${genRemFile}
        INCLUDE ${manualRemFile}
      '';

      systemd.user.services.ics2rem = {
        Unit = {
          Description = "Convert ics files to rem";
          # started via OnSuccess= of vdirsyncer.service
          After = [ "vdirsyncer.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${ics2remScript}";
        };
      };

      systemd.user.services.remind = lib._custom.mkWaylandService {
        Unit = {
          Description = "Remind is a sophisticated calendar and alarm program.";
          Documentation = "https://dianne.skoll.ca/projects/remind/";
        };
        Service = {
          # the INCLUDEd files must exist, remind errors out otherwise
          ExecStartPre = [
            "${pkgs.coreutils}/bin/touch ${genRemFile}"
            "${pkgs.coreutils}/bin/touch ${manualRemFile}"
          ];
          ExecStart = "${remindScript}";
          Restart = "on-failure";
          RestartSec = 5;
          KillMode = "mixed";
        };
      };

      # notifies reminders missed while suspended or powered off; also runs
      # on session start (via mkWaylandService WantedBy) to catch up after login
      systemd.user.services.remind-catchup = lib._custom.mkWaylandService {
        Unit.Description = "Notify reminders missed while suspended or powered off";
        Service = {
          Type = "oneshot";
          ExecStart = "${catchupScript}";
        };
      };

      systemd.user.timers.remind-catchup = {
        Unit.Description = "Watchdog for missed reminders";
        Timer = {
          OnCalendar = "*:0/2"; # every 2 minutes
          Unit = "remind-catchup.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
