{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.amfora;
  userName = config._userName;
in {
  options._custom.tui.amfora = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ amfora ];

    home-manager.users.${userName} = {
      xdg.configFile."amfora/config.toml".text = ''
        ${builtins.readFile ./dotfiles/config.toml}
        ${builtins.readFile "${inputs.catppuccin-amfora}/themes/mocha.toml"}
      '';
    };
  };
}
