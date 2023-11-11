{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/alacritty";
in {
  config = {
    environment = { systemPackages = with pkgs; [ unstable.alacritty ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "alacritty/catppuccin".source = inputs.catppuccin-alacritty;
        "alacritty/alacritty.yml".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/alacritty.yml";
      };
    };
  };
}
