{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/mixins/mbpfan";
in {
  config = {
    boot.kernelModules = [ "coretemp" "applesmc" ];
    environment = {
      systemPackages = with pkgs; [ mbpfan ];

      etc = {
        "scripts/rofi-mbpfan.sh" = {
          source = ./scripts/rofi-mbpfan.sh;
          mode = "0755";
        };
      };
    };
    # environment.etc."mbpfan.conf".source = ./dotfiles/mbpfan.conf;
    # environment.etc."mbpfan.conf".source =
    #   mkOutOfStoreSymlink "${configDirectory}/dotfiles/mbpfan.conf";
  };
}
