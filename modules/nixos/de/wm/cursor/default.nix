{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  cfg = config._custom.wm.cursor;
  userName = config._userName;
in {
  options._custom.wm.cursor = {
    enable = lib.mkEnableOption "setup gtk theme and apps";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ globals.cursor.package ];

    home-manager.users.${userName} = {
      home.pointerCursor = {
        inherit (globals.cursor) name package size;
        x11.enable = true;
        gtk.enable = true;
      };
    };
  };
}
