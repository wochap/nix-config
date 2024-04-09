{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.presenterm;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.programs.presenterm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ presenterm ];

      xdg.configFile."presenterm/config.yaml".source = pkgs.substituteAll {
        src = ./dotfiles/config.yaml;
        inherit (themeColors) flavor;
      };

      programs.zsh.initExtra = builtins.readFile ./dotfiles/p.zsh;
    };
  };
}
