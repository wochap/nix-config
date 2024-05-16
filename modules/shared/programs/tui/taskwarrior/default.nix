{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.taskwarrior;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  timewarriorConfigPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/timewarrior";
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

          "${timewarriorConfigPath}/hooks/on-modify.timewarrior" = {
            executable = true;
            source =
              "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
          };
        };

        shellAliases.twt = "taskwarrior-tui";
      };

      programs.taskwarrior = {
        enable = true;
        colorTheme = "dark-green-256";
        dataLocation =
          "${hmConfig.home.homeDirectory}/Sync/.config/taskwarrior";
        config = { };
        extraConfig = builtins.readFile ./dotfiles/taskrc;
      };
    };
  };
}

