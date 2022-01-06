{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      sessionVariables = {
        # Setup clipboard manager (clipmenu)
        CM_MAX_CLIPS = "30";
        CM_OWN_CLIPBOARD = "1";
        CM_SELECTIONS = "clipboard";
      };
    };
  };
}
