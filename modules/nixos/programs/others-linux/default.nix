{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.others-linux;
in {
  options._custom.programs.others-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      brave
      google-chrome
      microsoft-edge

      galaxy-buds-client
      libreoffice-fresh
      # antimicroX # map kb/mouse to gamepad
      # skypeforlinux
      # teamviewer
      # zoom-us
    ];
  };
}

