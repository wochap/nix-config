{ config, pkgs, lib, ... }:

let
  cfg = config._custom.weeb;
  inherit (config._custom.globals) configDirectory;
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

        # HACK: symlink since it needs to be writable
        "mangadesk/config.json".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/mangadesk.json;
      };
    };
  };
}
