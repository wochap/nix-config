{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.taskwarrior;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  timewarriorConfigPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/timewarrior";
in {
  options._custom.tui.taskwarrior = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        taskwarrior-tui
        timewarrior
        # TODO: setup bugwarrior
        python311Packages.bugwarrior
      ];
      home.sessionVariables = { TIMEWARRIORDB = timewarriorConfigPath; };
      home.file."${timewarriorConfigPath}/timewarrior.cfg".text = ''
        import ${pkgs.timewarrior}/share/doc/timew/doc/themes/dark_green.theme
        import ${pkgs.timewarrior}/share/doc/timew/doc/holidays/holidays.en-US
        ${builtins.readFile ./dotfiles/timewarrior.cfg}
      '';

      home.shellAliases = { twt = "taskwarrior-tui"; };

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

