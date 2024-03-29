{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.alacritty;
  inherit (config._custom.globals) configDirectory;
  inherit (lib._custom) relativeSymlink;
in {
  options._custom.programs.alacritty.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ alacritty ];

      xdg.configFile = {
        "alacritty/catppuccin".source = inputs.catppuccin-alacritty;
        "alacritty/alacritty.toml".source =
          relativeSymlink configDirectory ./dotfiles/alacritty.toml;
      };
    };
  };
}
