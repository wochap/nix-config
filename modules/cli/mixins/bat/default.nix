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
        config = { theme = "Catppuccin-mocha"; };
        themes = {
          # HACK: without builtins.readFile bat doesn't recognize the file
          Catppuccin-mocha = builtins.readFile
            "${inputs.catppuccin-bat}/Catppuccin-mocha.tmTheme";
        };
      };
    };
  };
}
