{ config, pkgs, lib, libAttr, ... }:

let
  cfg = config._custom.xorgWm;
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/users/mixins/waybar";
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ waybar libevdev ];
      etc = {
        "scripts/waybar/waybar-toggle.sh" = {
          source = ./scripts/waybar-toggle.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "waybar/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
        "waybar/style.css".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/style.css";
        "waybar/colors.css".text = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "@define-color ${key} ${value};") theme)}
        '';
      };
    };
  };
}
