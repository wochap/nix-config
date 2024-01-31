{ config, lib, inputs, ... }:

let
  cfg = config._custom.cli.starship;
  userName = config._userName;
  themeSettings = builtins.fromTOML
    (builtins.readFile "${inputs.catppuccin-starship}/palettes/mocha.toml");
in {
  options._custom.cli.starship = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      xdg.configFile."starship-transient.toml".text = ''
        add_newline = false
        palette = "catppuccin_mocha"
        format = "$character"
        ${builtins.readFile "${inputs.catppuccin-starship}/palettes/mocha.toml"}
      '';

      programs.starship = {
        enable = true;
        settings = lib.recursiveUpdate themeSettings {
          add_newline = true;
          nix_shell.disabled = true;
          lua.disabled = true;
          package.disabled = true;
          time = {
            disabled = false;
            time_format = "%R";
          };
          fill.symbol = " ";
          format = lib.concatStrings [
            "$all"
            "$fill"
            "$nodejs"
            "$cmd_duration"
            "$jobs"
            "$time"
            "$line_break"
            "$battery"
            "$container"
            "$character"
          ];

          # Setup theme
          palette = "catppuccin_mocha";
        };
      };
    };
  };
}
