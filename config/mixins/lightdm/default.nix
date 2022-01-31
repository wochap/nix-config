{ config, pkgs, lib, ... }:

let isHidpi = config._isHidpi;
in {
  config = {
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
            name = "Tela-purple-dark";
            package = pkgs.tela-icon-theme;
          };

          theme = {
            name = "Dracula";
            package = pkgs.dracula-theme;
          };

          extraConfig = ''
            font-name=Inter 10
          '';
          indicators =
            [ "~spacer" "~session" "~power" ];
        };
      };
    };
  };
}
