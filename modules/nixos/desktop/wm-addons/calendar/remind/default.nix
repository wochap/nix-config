{
  config,
  inputs,
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

  remindScript = pkgs.writeShellScript "remind" ''
    exec ${pkgs.python3}/bin/python3 ${./remind_notify.py} \
      ${pkgs.remind}/bin/remind \
      ${pkgs.libnotify}/bin/notify-send \
      ${remFilePath}
  '';
  python-remind-final = pkgs._custom.pythonPackages.python-remind;
  # --posttime: timed events additionally notify cfg.preAlert (default 15
  # minutes) before start (remind always notifies at the event start too)
  ics2remScript = pkgs.writeShellScript "ics2rem" ''
    ${pkgs.coreutils-full}/bin/echo "ics2rem start"
    ${pkgs.coreutils}/bin/mkdir -p ${remindConfigDir}
    # ics2rem PUSH/POP-OMIT-CONTEXT blocks must stay ordered.
    ${pkgs.findutils}/bin/find ${vdirsyncerDataDir} -name '*.ics' -print0 \
      | LC_ALL=C ${pkgs.coreutils-full}/bin/sort -z \
      | ${pkgs.findutils}/bin/xargs -0 -r -n1 ${python-remind-final}/bin/ics2rem --posttime "${cfg.preAlert}" \
      > "${genRemFile}.tmp"
    # The daemon may read this file during regeneration.
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
    nixpkgs.overlays = [
      (_final: prev: {
        remind = prev.remind.overrideAttrs (_oldAttrs: {
          version = "06.02.10";
          src = inputs.remind;
        });
      })
    ];

    _custom.hm = {
      home.packages = with pkgs; [
        remind
        python-remind-final # ics2rem
      ];

      xdg.configFile."remind/remind.rem".text = ''
        # This file is managed, put your own reminders into ${manualRemFile}.
        INCLUDE ${genRemFile}
        INCLUDE ${manualRemFile}
      '';

      systemd.user.services.ics2rem = {
        Unit = {
          Description = "Convert ics files to rem";
          After = [ "vdirsyncer.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/flock %t/vdirsyncer-calendar.lock ${ics2remScript}";
          # Daemon mode queues timed reminders in memory. Reload that queue
          # after an event is added, removed, or moved by a calendar sync.
          ExecStartPost = "${pkgs.systemd}/bin/systemctl --user try-reload-or-restart remind.service";
        };
      };

      systemd.user.services.remind = lib._custom.mkWaylandService {
        Unit = {
          Description = "Remind is a sophisticated calendar and alarm program.";
          Documentation = "https://dianne.skoll.ca/projects/remind/";
          # Avoid notification storms if remind repeatedly crashes.
          StartLimitIntervalSec = 60;
          StartLimitBurst = 3;
        };
        Service = {
          # remind rejects missing INCLUDE targets.
          ExecStartPre = [
            "${pkgs.coreutils}/bin/touch ${genRemFile}"
            "${pkgs.coreutils}/bin/touch ${manualRemFile}"
          ];
          ExecStart = "${remindScript}";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
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
          StateDirectory = "remind";
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
