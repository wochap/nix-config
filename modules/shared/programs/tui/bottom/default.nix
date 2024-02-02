{ config, lib, inputs, ... }:

let
  cfg = config._custom.tui.bottom;
  themeSettings = builtins.fromTOML
    (builtins.readFile "${inputs.catppuccin-bottom}/themes/mocha.toml");
in {
  options._custom.tui.bottom.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.shellAliases = { top = "btm"; };

      programs.bottom = {
        enable = true;
        settings = lib.recursiveUpdate themeSettings {
          flags = {
            process_command = true;
            group_processes = true;
            mem_as_value = true;
            tree = true;
            basic = true;
          };
        };
      };
    };
  };
}
