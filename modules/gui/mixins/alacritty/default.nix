{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gui.alacritty;
  userName = config._userName;
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (pkgs._custom.runtimePath config._custom.globals.configDirectory path);
in {
  options._custom.gui.alacritty = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ unstable.alacritty ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "alacritty/catppuccin".source = inputs.catppuccin-alacritty;
        "alacritty/alacritty.yml".source = relativeSymlink ./dotfiles/alacritty.yml;
      };
    };
  };
}
