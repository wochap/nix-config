{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.cli.starship;
  userName = config._userName;
  themeSettings = builtins.fromTOML
    (builtins.readFile "${inputs.catppuccin-starship}/palettes/mocha.toml");
in {
  options._custom.cli.starship = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {

      programs.starship = {
        enable = true;
        settings = lib.recursiveUpdate themeSettings {
          add_newline = false;
          nix_shell = { disabled = true; };
          lua = { disabled = true; };
          package = { disabled = true; };

          # Setup theme
          palette = "catppuccin_mocha";
        };
      };
    };
  };
}
