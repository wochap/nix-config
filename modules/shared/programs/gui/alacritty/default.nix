{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gui.alacritty;
  inherit (config._custom.globals) configDirectory;
  inherit (lib._custom) relativeSymlink;
in {
  options._custom.gui.alacritty = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ unstable.alacritty ]; };

    _custom.hm = {
      xdg.configFile = {
        "alacritty/catppuccin".source = inputs.catppuccin-alacritty;
        "alacritty/alacritty.yml".source =
          relativeSymlink configDirectory ./dotfiles/alacritty.yml;
      };
    };
  };
}
