{ config, pkgs, lib, ... }:

let
  cfg = config._custom.xorgWm;
  userName = config._userName;
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ clipmenu ];

      sessionVariables = {
        # Setup clipboard manager (clipmenu)
        CM_MAX_CLIPS = "30";
        CM_OWN_CLIPBOARD = "1";
        CM_SELECTIONS = "clipboard";
      };
    };
  };
}
