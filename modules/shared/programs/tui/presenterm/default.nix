{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.presenterm;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.programs.presenterm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ nixpkgs-unstable.presenterm ];

      xdg.configFile."presenterm/config.yaml".source =
        pkgs.replaceVars ./dotfiles/config.yaml {
          inherit (themeColors) flavor;
        };

      programs.zsh.initContent = builtins.readFile ./dotfiles/p.zsh;
    };
  };
}
