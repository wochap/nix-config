{ config, lib, inputs, ... }:

let cfg = config._custom.cli.bat;
in {
  options._custom.cli.bat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        shellAliases = {
          cat = "bat --plain";
          bathelp = "bat --plain --language=help";
        };
        sessionVariables = { MANPAGER = "sh -c 'col -bx | bat -l man -p'"; };
      };

      programs.bat = {
        enable = true;
        config = { theme = "Catppuccin-mocha"; };
        themes = {
          Catppuccin-mocha = {
            src = inputs.catppuccin-bat;
            file = "Catppuccin-mocha.tmTheme";
          };
        };
      };
    };
  };
}
