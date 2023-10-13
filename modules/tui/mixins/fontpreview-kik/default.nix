{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.fontpreview-kik;
  userName = config._userName;
  inherit (config._custom.globals) themeColors;
  fontpreview-kik = pkgs.writeShellScriptBin "fontpreview-kik"
    (builtins.readFile ./scripts/fontpreview-kik.sh);
in {
  options._custom.tui.fontpreview-kik = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [ fontpreview-kik ];
        shellAliases = {
          fp =
            "fontpreview-kik -b ${themeColors.background} -f ${themeColors.foreground}";
        };
      };
    };
  };
}
