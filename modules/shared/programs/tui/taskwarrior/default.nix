{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.taskwarrior;
  inherit (config._custom.globals) userName secrets;
  hmConfig = config.home-manager.users.${userName};

  timewarriorConfigPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/timewarrior";
  taskwarriorDataPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/taskwarrior";
  taskwarrior-final = pkgs.taskwarrior3;
  stop-tasks = pkgs.writeScriptBin "stop-tasks" ''
    #!/usr/bin/env bash
    echo y | ${taskwarrior-final}/bin/task status:pending stop
  '';
in {
  options._custom.programs.taskwarrior.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = with pkgs; [
          taskwarrior-tui
          timewarrior
          pkgs._custom.pythonPackages.bugwarrior
        ];

        sessionVariables.TIMEWARRIORDB = timewarriorConfigPath;

        file = {
          "${timewarriorConfigPath}/timewarrior.cfg".text = ''
            import ${pkgs.timewarrior}/share/doc/timew/themes/dark_green.theme
            import ${pkgs.timewarrior}/share/doc/timew/holidays/holidays.en-US
            ${builtins.readFile ./dotfiles/timewarrior.cfg}
          '';

          "${taskwarriorDataPath}/hooks/on-modify.timewarrior" = {
            executable = true;
            source =
              "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
          };
        };

        shellAliases.twt = "taskwarrior-tui";
      };
      xdg.configFile."bugwarrior/bugwarrior.toml".source =
        pkgs.replaceVars ./dotfiles/bugwarrior.toml {
          seEmail = secrets.se.email;
        };

      programs.taskwarrior = {
        enable = true;
        package = taskwarrior-final;
        colorTheme = "${taskwarrior-final}/share/doc/task/rc/dark-green-256";
        dataLocation = taskwarriorDataPath;
        config = { };
        extraConfig = builtins.readFile ./dotfiles/taskrc;
      };

      # stop timewarrior on shutdown|logout|suspend
      systemd.user.services = {
        stop-taskwarrior-on-glogout = lib._custom.mkGraphicalService {
          Service = {
            Environment = [ "TIMEWARRIORDB=${timewarriorConfigPath}" ];
            Type = "oneshot";
            ExecStop = "${stop-tasks}/bin/stop-tasks";
            RemainAfterExit = true;
          };
        };
        stop-taskwarrior-on-sleep = {
          Unit.Before = [
            "sleep.target"
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
          ];
          Install.WantedBy = [
            "sleep.target"
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
          ];
          Service = {
            User = userName;
            Environment = [ "TIMEWARRIORDB=${timewarriorConfigPath}" ];
            Type = "oneshot";
            ExecStart = "${stop-tasks}/bin/stop-tasks";
          };
        };
        stop-taskwarrior-on-shutdown = {
          Unit = {
            DefaultDependencies = "no";
            Before = [ "shutdown.target" "reboot.target" "halt.target" ];
          };
          Install.WantedBy =
            [ "shutdown.target" "reboot.target" "halt.target" ];
          Service = {
            User = userName;
            Environment = [ "TIMEWARRIORDB=${timewarriorConfigPath}" ];
            Type = "oneshot";
            ExecStart = "${stop-tasks}/bin/stop-tasks";
          };
        };
      };
    };
  };
}

