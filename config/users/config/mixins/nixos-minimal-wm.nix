{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {
      # TODO: add common config between minimal wm?
    };
  };
}
