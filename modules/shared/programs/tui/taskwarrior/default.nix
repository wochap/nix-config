{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.taskwarrior;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  timewarriorConfigPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/timewarrior";
  taskwarriorConfigPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/taskwarrior";
  taskwarrior-final = pkgs.nextstable-nixpkgs.taskwarrior3;
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
          # TODO: setup bugwarrior
          python311Packages.bugwarrior
        ];

        sessionVariables.TIMEWARRIORDB = timewarriorConfigPath;

        file = {
          "${timewarriorConfigPath}/timewarrior.cfg".text = ''
            import ${pkgs.timewarrior}/share/doc/timew/doc/themes/dark_green.theme
            import ${pkgs.timewarrior}/share/doc/timew/doc/holidays/holidays.en-US
            ${builtins.readFile ./dotfiles/timewarrior.cfg}
          '';

          "${taskwarriorConfigPath}/hooks/on-modify.timewarrior" = {
            executable = true;
            source =
              "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
          };
        };

        shellAliases.twt = "taskwarrior-tui";
      };

      programs.taskwarrior = {
        enable = true;
        package = taskwarrior-final;
        colorTheme = "dark-green-256";
        dataLocation = taskwarriorConfigPath;
        config = { };
        extraConfig = builtins.readFile ./dotfiles/taskrc;
      };

      systemd.user.services = {
        stop-taskwarrior = lib._custom.mkGraphicalService {
          Service = {
            Environment = [ "TIMEWARRIORDB=${timewarriorConfigPath}" ];
            PassEnvironment = [ "PATH" ];
            Type = "oneshot";
            ExecStop = "${stop-tasks}/bin/stop-tasks";
            RemainAfterExit = true;
          };
        };
      };
    };
  };
}

