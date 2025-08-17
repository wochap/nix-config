{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.taskwarrior;
  inherit (config._custom.globals) userName secrets;
  hmConfig = config.home-manager.users.${userName};

  timewarrior-final = pkgs.timewarrior;
  timewarriorConfigPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/timewarrior";
  taskwarriorDataPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/taskwarrior";
  taskwarrior-final = pkgs.taskwarrior3;
  stop-tasks = pkgs.writeScriptBin "stop-tasks" ''
    #!${pkgs.bash}/bin/bash
    echo y | ${taskwarrior-final}/bin/task status:pending stop
  '';
in {
  options._custom.programs.taskwarrior.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # stop timewarrior on shutdown and suspend
    systemd.services = {
      stop-taskwarrior-on-sleep = {
        wantedBy = [
          "sleep.target"
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        before = [
          "sleep.target"
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        environment.TIMEWARRIORDB = timewarriorConfigPath;
        path = [ pkgs.python314 timewarrior-final ];
        serviceConfig = {
          Type = "oneshot";
          User = userName;
        };
        script = "${stop-tasks}/bin/stop-tasks";
      };
      stop-taskwarrior-on-shutdown = {
        before = [ "shutdown.target" "reboot.target" "halt.target" ];
        wantedBy = [ "shutdown.target" "reboot.target" "halt.target" ];
        environment.TIMEWARRIORDB = timewarriorConfigPath;
        path = [ pkgs.python314 timewarrior-final ];
        unitConfig.defaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          User = userName;
        };
        script = "${stop-tasks}/bin/stop-tasks";
      };
    };

    _custom.hm = {
      home = {
        packages = with pkgs; [
          taskwarrior-tui
          timewarrior-final
          pkgs._custom.pythonPackages.bugwarrior
        ];

        sessionVariables.TIMEWARRIORDB = timewarriorConfigPath;

        file = {
          "${timewarriorConfigPath}/timewarrior.cfg".text = ''
            import ${timewarrior-final}/share/doc/timew/themes/dark_green.theme
            import ${timewarrior-final}/share/doc/timew/holidays/holidays.en-US
            ${builtins.readFile ./dotfiles/timewarrior.cfg}
          '';

          "${taskwarriorDataPath}/hooks/on-modify.timewarrior" = {
            executable = true;
            source =
              "${timewarrior-final}/share/doc/timew/ext/on-modify.timewarrior";
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

      # stop timewarrior on logout
      systemd.user.services = {
        stop-taskwarrior-on-glogout = lib._custom.mkGraphicalService {
          Service = {
            Environment = [ "TIMEWARRIORDB=${timewarriorConfigPath}" ];
            Type = "oneshot";
            ExecStop = "${stop-tasks}/bin/stop-tasks";
            RemainAfterExit = true;
          };
        };
      };
    };
  };
}

