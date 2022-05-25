{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.lightdm;
  globals = config._custom.globals;
in {
  options._custom.lightdm = { enable = lib.mkEnableOption {}; };

  config = lib.mkIf cfg.enable {
    services.xserver.displayManager = {
      lightdm = {
        enable = true;
        background = lib.mkForce ./assets/wallpaper.jpg;
        greeters.gtk = {
          enable = true;

          cursorTheme = {
            name = globals.cursor.name;
            package = globals.cursor.package;
            size = globals.cursor.size;
          };

          iconTheme = {
            name = "Tela-purple-dark";
            package = pkgs.tela-icon-theme;
          };

          theme = {
            name = globals.theme.name;
            package = globals.theme.package;
          };

          extraConfig = ''
            font-name=${globals.fonts.sans}
          '';
          indicators = [ "~spacer" "~session" "~power" ];
        };
      };
    };
  };
}
