{ config, lib, pkgs, ... }:

let
  cfg = config._custom.xorgWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/xorg-wm/users/mixins/xsettingsd";
in {
  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ xsettingsd ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {

        # Gtk settings
        # https://github.com/GNOME/gnome-settings-daemon/blob/master/plugins/xsettings/gsd-xsettings-manager.c
        "xsettingsd/xsettingsd.conf".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/xsettingsd.conf";
      };
    };
  };
}