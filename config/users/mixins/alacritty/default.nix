{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    environment = { systemPackages = with pkgs; [ unstable.alacritty ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "alacritty/catppuccin".source = inputs.catppuccin-alacritty;
        "alacritty/alacritty.yml".source = ./dotfiles/alacritty.yml;
      };
    };
  };
}
