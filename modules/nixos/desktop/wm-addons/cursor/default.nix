{ config, lib, ... }:

let
  inherit (config._custom) globals;
  cfg = config._custom.desktop.cursor;
in {
  options._custom.desktop.cursor.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ globals.cursor.package ];

    _custom.hm = {
      home.pointerCursor = {
        inherit (globals.cursor) name package size;
        x11.enable = true;
        gtk.enable = true;
      };

      gtk.cursorTheme = { inherit (globals.cursor) package name size; };
    };
  };
}
