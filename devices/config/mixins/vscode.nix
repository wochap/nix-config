{ config, pkgs, lib, ... }:

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
