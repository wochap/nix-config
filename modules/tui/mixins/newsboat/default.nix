{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.newsboat;
  userName = config._userName;

  qndl = pkgs.writeShellScriptBin "qndl" (builtins.readFile ./scripts/qndl.sh);
  linkhandler = pkgs.writeShellScriptBin "linkhandler"
    (builtins.readFile ./scripts/linkhandler.sh);
in {
  options._custom.tui.newsboat = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ newsboat qndl linkhandler ];

      xdg.configFile = {
        "newsboat/catppuccin-dark".source =
          "${inputs.catppuccin-newsboat}/themes/dark";
        "newsboat/urls".source = ./dotfiles/urls;
        "newsboat/config".source = ./dotfiles/config;
      };
    };
  };
}
