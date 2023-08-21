{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        trash-cli # required by vscode
        vscode
      ];

      sessionVariables = {
        # Fix vscode delete
        ELECTRON_TRASH="trash-cli";
      };
    };
  };
}
