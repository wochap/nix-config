{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home.shellAliases = { top = "btm"; };

      programs.bottom = {
        enable = true;
        settings = {
          flags = {
            process_command = true;
            group_processes = true;
            mem_as_value = true;
            tree = true;
            basic = true;
          };
        } // builtins.fromTOML
          (builtins.readFile "${inputs.catppuccin-bottom}/themes/mocha.toml");
      };
    };
  };
}
