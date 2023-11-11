{ config, pkgs, lib, ... }:

let cfg = config._custom.gui.vscode;
in {
  options._custom.gui.vscode = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        trash-cli # required by vscode
        vscode
      ];

      sessionVariables = {
        # Fix vscode delete
        ELECTRON_TRASH = "trash-cli";
      };
    };
  };
}
