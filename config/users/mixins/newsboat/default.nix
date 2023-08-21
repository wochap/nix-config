{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/newsboat";

  qndl = pkgs.writeShellScriptBin "qndl" (builtins.readFile ./scripts/qndl.sh);
  linkhandler = pkgs.writeShellScriptBin "linkhandler"
    (builtins.readFile ./scripts/linkhandler.sh);
in {
  config = {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ newsboat qndl linkhandler ];

      xdg.configFile = {
        "newsboat/urls".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/urls";
        "newsboat/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
      };
    };
  };
}
