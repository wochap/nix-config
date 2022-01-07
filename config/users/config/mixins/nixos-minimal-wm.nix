{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {

      # HACK: let home-manager xsession do the rest
      services.xserver.displayManager = {
        defaultSession = "none+hm";
        session = [{
          manage = "window";
          name = "hm";
          start = "";
        }];
      };
    };
  };
}
