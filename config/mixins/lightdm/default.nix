{ config, pkgs, lib, inputs, ... }:

let globals = import ../globals.nix { inherit config pkgs lib inputs; };
in {
  config = {
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
            font-name=${globals.fonts.sans} 10
          '';
          indicators = [ "~spacer" "~session" "~power" ];
        };
      };
    };
  };
}
