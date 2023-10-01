{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.wtf;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/tui/mixins/wtf";
  customWtf = pkgs.writeTextFile {
    name = "wtf";
    destination = "/bin/wtf";
    executable = true;
    text = ''
      #!/usr/bin/env bash

      WTF_JIRA_API_KEY=$(${pkgs.coreutils}/bin/cat ${hmConfig.xdg.configHome}/secrets/jira/geanb@bandofcoders.com)
      WTF_JIRA_API_KEY="$WTF_JIRA_API_KEY" wtfutil
    '';
  };
in {
  options._custom.tui.wtf = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ unstable.wtf customWtf ];

      xdg.configFile."wtf/config.yml".source =
        mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.yml";
    };
  };
}
