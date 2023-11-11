{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.mangadesk;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/tui/mixins/mangadesk";
in {
  options._custom.tui.mangadesk = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ _custom.mangadesk ];

      xdg.configFile = {
        "mangadesk/config.json".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.json";
      };
    };
  };
}
