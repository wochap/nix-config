{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in {
  config = {
    services.xserver.displayManager = {
      defaultSession = "none+hm";
      session = [{
        manage = "window";
        name = "hm";
        start = ''
          $HOME/.xsession-hm &
          waitPID=$!
        '';
      }];
    };

    home-manager.users.${userName} = {
      home.file = {
        ".local/share/fonts/woos.ttf".source = ./assets/woos/fonts/woos.ttf;
      };
    };
  };
}
