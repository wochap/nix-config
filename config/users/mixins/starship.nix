{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  themeSettings = builtins.fromTOML
    (builtins.readFile "${inputs.catppuccin-starship}/palettes/mocha.toml");
in {
  config = {
    home-manager.users.${userName} = {

      programs.starship = {
        enable = true;
        settings = lib.recursiveUpdate themeSettings {
          add_newline = false;
          nix_shell = { disabled = true; };
          package = { disabled = true; };

          # Setup theme
          palette = "catppuccin_mocha";
        };
      };
    };
  };
}
