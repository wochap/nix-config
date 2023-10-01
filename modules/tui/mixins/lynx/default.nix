{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.lynx;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/tui/mixins/lynx";
in {
  options._custom.tui.lynx = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [ lynx ];
        sessionVariables = {
          LYNX_CFG = "${hmConfig.xdg.configHome}/lynx/lynx.cfg";
          LYNX_LSS = "${hmConfig.xdg.configHome}/lynx/lynx.lss";
        };
      };

      xdg.configFile."lynx/lynx.cfg".source =
        mkOutOfStoreSymlink "${currentDirectory}/dotfiles/lynx.cfg";
      xdg.configFile."lynx/lynx.lss".source =
        mkOutOfStoreSymlink "${currentDirectory}/dotfiles/lynx.lss";
    };
  };
}
