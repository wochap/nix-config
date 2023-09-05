{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  themeSettings = builtins.fromTOML
    (builtins.readFile "${inputs.catppuccin-bottom}/themes/mocha.toml");
in {
  config = {
    home-manager.users.${userName} = {
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
