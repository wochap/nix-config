{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.taskwarrior;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  timewarriorConfigPath =
    "${hmConfig.home.homeDirectory}/Sync/.config/timewarrior";
in {
  options._custom.tui.taskwarrior = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
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

