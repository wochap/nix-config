{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home.shellAliases = { top = "btm"; };

      programs.bottom = {
        enable = true;
        settings = {
          flags = {
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
