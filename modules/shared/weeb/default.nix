{ config, pkgs, lib, ... }:

let cfg = config._custom.weeb;
in {
  options._custom.weeb.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        _custom.mangadesk
        _custom.pythonPackages.animdl
        ani-cli
        mangal
      ];

      xdg.configFile = {
        "mangal/mangal.toml".source = ./dotfiles/mangal.toml;
        "mangadesk/config.json".source = ./dotfiles/config.json;
      };
    };
  };
}
