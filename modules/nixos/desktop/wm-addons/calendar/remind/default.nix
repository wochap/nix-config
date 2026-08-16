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
  remindConfigDir = "${configHome}/remind";
  vdirsyncerDataDir = "${dataHome}/vdirsyncer";
  remFilePath = "${remindConfigDir}/remind.rem";
  # regenerated from the synced ics files after every vdirsyncer sync
  genRemFile = "${remindConfigDir}/calendar-generated.rem";
  # user-managed file for hand-written reminders (see README)
  manualRemFile = "${remindConfigDir}/manual.rem";
  # epoch of the last successful remind-catchup run
  catchupStateFile = "${stateHome}/remind/last-check";

  notifyScript = pkgs.writeShellScript "remind-notify" ''
    minutes="$1"
    body="$2"

    if [ "$minutes" -gt 0 ]; then
      exec ${pkgs.libnotify}/bin/notify-send \
        --app-name="remind" \
        --app-icon=kalarm \
        --icon=kalarm \
        --hint=string:custom-sound:message \
        "Upcoming reminder (in $minutes minutes)" \
        "$body"
    fi

    exec ${pkgs.libnotify}/bin/notify-send \
      --app-name=remind \
      --app-icon=kalarm \
      --icon=kalarm \
      --urgency=critical \
      --hint=string:custom-sound:message \
      "Reminder — starting now" \
      "$body"
  '';
  remindScript = pkgs.writeShellScript "remind" ''
    # %4 is the number of minutes from delivery to the event's AT time.
    ${pkgs.remind}/bin/remind -z -k'${notifyScript} %4 "%s" &' ${remFilePath}
  '';
  python-remind-final = pkgs._custom.pythonPackages.python-remind;
  # --posttime: timed events additionally notify cfg.preAlert (default 15
  # minutes) before start (remind always notifies at the event start too)
  ics2remScript = pkgs.writeShellScript "ics2rem" ''
    ${pkgs.coreutils-full}/bin/echo "ics2rem start"
    ${pkgs.coreutils}/bin/mkdir -p ${remindConfigDir}
    ${pkgs.findutils}/bin/find ${vdirsyncerDataDir} -name '*.ics' -exec ${python-remind-final}/bin/ics2rem --posttime "${cfg.preAlert}" {} \; | LC_ALL=C ${pkgs.coreutils-full}/bin/sort -k2,2M -k3,3n > "${genRemFile}.tmp"
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
        }
        // lib._custom.userServiceHardening
        // {
          ProtectHome = "tmpfs";
          BindReadOnlyPaths = [ vdirsyncerDataDir ];
          BindPaths = [ remindConfigDir ];
          RestrictAddressFamilies = [ ];
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
        }
        // lib._custom.userServiceHardening
        // {
          ProtectHome = "tmpfs";
          BindPaths = [ remindConfigDir ];
          RestrictAddressFamilies = [ "AF_UNIX" ];
        };
      };

      # notifies reminders missed while suspended or powered off; also runs
      # on session start (via mkWaylandService WantedBy) to catch up after login
      systemd.user.services.remind-catchup = lib._custom.mkWaylandService {
        Unit.Description = "Notify reminders missed while suspended or powered off";
        Service = {
          Type = "oneshot";
          ExecStart = "${catchupScript}";
        }
        // lib._custom.userServiceHardening
        // {
          ProtectHome = "tmpfs";
          BindReadOnlyPaths = [ remindConfigDir ];
          StateDirectory = "remind";
          RestrictAddressFamilies = [ "AF_UNIX" ];
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
