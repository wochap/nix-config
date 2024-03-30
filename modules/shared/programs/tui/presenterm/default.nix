{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.presenterm;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.programs.presenterm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ presenterm ];

      xdg.configFile."presenterm/config.yaml".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/config.yaml;

      programs.zsh.initExtra = builtins.readFile ./dotfiles/p.zsh;
    };
  };
}
