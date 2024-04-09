{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.alacritty;
  inherit (config._custom.globals) configDirectory themeColors;
  inherit (lib._custom) relativeSymlink;
in {
  options._custom.programs.alacritty.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ alacritty ];

      xdg.configFile = {
        "alacritty/catppuccin".source = inputs.catppuccin-alacritty;
        "alacritty/alacritty.toml".text = ''
          import = [
          "~/.config/alacritty/catppuccin/catppuccin-${themeColors.flavor}.toml",
          "~/.config/alacritty/config.toml",
          ]
        '';
        "alacritty/config.toml".source =
          relativeSymlink configDirectory ./dotfiles/config.toml;
      };
    };
  };
}
