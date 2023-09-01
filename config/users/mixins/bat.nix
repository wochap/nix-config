{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home = {
        shellAliases = { cat = "bat"; };
        sessionVariables = { MANPAGER = "sh -c 'col -bx | bat -l man -p'"; };
      };

      programs.bat = {
        enable = true;
        config = { theme = "Dracula"; };
        themes = { dracula = "${inputs.dracula-sublime}/Dracula.tmTheme"; };
      };
    };
  };
}
