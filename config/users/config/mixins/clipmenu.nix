{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment.sessionVariables = {
      # Setup clipboard manager (clipmenu)
      CM_MAX_CLIPS = "30";
      CM_OWN_CLIPBOARD = "1";
      CM_SELECTIONS = "clipboard";
    };

    home-manager.users.${userName} = {
      services.clipmenu.enable = true;
    };
  };
}
