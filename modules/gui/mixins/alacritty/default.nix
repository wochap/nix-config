{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gui.alacritty;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/gui/mixins/alacritty";
in {
  options._custom.gui.alacritty = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
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
