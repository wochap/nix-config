{ config, lib, inputs, ... }:

let
  cfg = config._custom.programs.bottom;
  inherit (config._custom.globals) themeColors;
  themeSettings = builtins.fromTOML (builtins.readFile
    "${inputs.catppuccin-bottom}/themes/${themeColors.flavor}.toml");
in {
  options._custom.programs.bottom.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.shellAliases.top = "btm";

      programs.bottom = {
        enable = true;
        settings = lib.recursiveUpdate themeSettings {
          flags = {
            process_command = true;
            group_processes = false;
            mem_as_value = true;
            tree = false;
            basic = true;
          };
          processes = {
            columns = [
              "PID"
              "Name"
              "CPU%"
              "Mem%"
              "User"
              "State"
            ];
          };
        };
      };
    };
  };
}
