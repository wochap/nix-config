{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.fastfetch;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.desktop.fastfetch.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ fastfetch ];

      xdg.configFile."fastfetch/config.jsonc".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/config.jsonc;

      home.shellAliases.ff = "fastfetch";
    };
  };
}
