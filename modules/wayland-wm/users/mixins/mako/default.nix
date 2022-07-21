{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/users/mixins/mako";
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ mako libnotify dunst ];
      etc = {
        "assets/notification.flac" = {
          source = ./assets/notification.flac;
          mode = "0755";
        };
        "scripts/mako/mako-toggle-mode.sh" = {
          source = ./scripts/mako-toggle-mode.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "mako/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
      };
    };
  };
}

