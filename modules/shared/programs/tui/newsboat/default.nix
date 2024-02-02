{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.newsboat;

  qndl = pkgs.writeShellScriptBin "qndl" (builtins.readFile ./scripts/qndl.sh);
  linkhandler = pkgs.writeShellScriptBin "linkhandler"
    (builtins.readFile ./scripts/linkhandler.sh);
in {
  options._custom.tui.newsboat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
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
