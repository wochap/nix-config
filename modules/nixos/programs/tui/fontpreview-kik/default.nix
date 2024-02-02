{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.fontpreview-kik;
  inherit (config._custom.globals) themeColors;
  fontpreview-kik = pkgs.writeShellScriptBin "fontpreview-kik"
    (builtins.readFile ./scripts/fontpreview-kik.sh);
in {
  options._custom.tui.fontpreview-kik.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = [ fontpreview-kik ];
        shellAliases = {
          fp =
            "fontpreview-kik -b '${themeColors.background}' -f '${themeColors.foreground}'";
        };
      };
    };
  };
}
