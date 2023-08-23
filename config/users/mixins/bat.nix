{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home.shellAliases = { cat = "bat"; };

      programs.bat = {
        enable = true;
        config = { theme = "Dracula"; };
        themes = { dracula = "${inputs.dracula-sublime}/Dracula.tmTheme"; };
      };
    };
  };
}
