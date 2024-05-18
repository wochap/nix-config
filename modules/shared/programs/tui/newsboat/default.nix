{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.newsboat;
  inherit (config._custom.globals) themeColors;

  qndl = pkgs.writeShellScriptBin "qndl" (builtins.readFile ./scripts/qndl.sh);
  linkhandler = pkgs.writeShellScriptBin "linkhandler"
    (builtins.readFile ./scripts/linkhandler.sh);
in {
  options._custom.programs.newsboat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        newsboat
        qndl
        linkhandler
        urlscan # extract urls from emails/txt files
      ];

      xdg.configFile = {
        "newsboat/catppuccin-dark".source =
          "${inputs.catppuccin-newsboat}/themes/${
            if themeColors.flavor == "latte" then "latte" else "dark"
          }";
        "newsboat/urls".source = ./dotfiles/urls;
        "newsboat/config".source = ./dotfiles/config;
      };
    };
  };
}
