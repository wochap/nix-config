{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {

      programs.starship = {
        enable = true;
        settings = {
          add_newline = false;
          nix_shell = { disabled = true; };
          package = { disabled = true; };

          # Setup theme
          palette = "catppuccin_mocha";
        } // builtins.fromTOML (builtins.readFile
          "${inputs.catppuccin-starship}/palettes/mocha.toml");
      };
    };
  };
}
