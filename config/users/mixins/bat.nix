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
        themes = {
          Dracula = "${inputs.dracula-sublime}/Dracula.tmTheme";

          # TODO: Catppuccin-mocha doesn't work
          # $ bat cache --build
          # Failed to load one or more themes from '/home/gean/.config/bat/themes' (reason: 'Invalid syntax theme settings')
          # Catppuccin-mocha =
          #   "${inputs.catppuccin-bat}/Catppuccin-mocha.tmTheme";
        };
      };
    };
  };
}
