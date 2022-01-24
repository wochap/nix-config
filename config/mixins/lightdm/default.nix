{ config, pkgs, lib, ... }:

let isHidpi = config._isHidpi;
in {
  config = {

    # Setup login screen
    services.xserver.displayManager = {
      lightdm = {
        enable = true;
        background = lib.mkForce ./assets/wallpaper.jpg;
        greeters.gtk = {
          enable = true;

          cursorTheme = {
            name = "Numix-Cursor";
            package = pkgs.numix-cursor-theme;
            size = if isHidpi then 40 else 32;
          };

          iconTheme = {
            name = "Tela";
            package = pkgs.tela-icon-theme;
          };

          theme = {
            name = "Orchis-dark";
            package = pkgs.orchis;
          };

          extraConfig = ''
            font-name=Inter 9
          '';
          indicators =
            [ "~host" "~spacer" "~clock" "~spacer" "~session" "~power" ];
        };
      };
    };
  };
}
