{ config, pkgs, lib, inputs, system, ... }:

let cfg = config._custom.programs.others-linux;
in {
  options._custom.programs.others-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      brave
      prevstable-chrome.google-chrome
      prevstable-msedge.microsoft-edge
      inputs.zen-browser.packages."${system}".beta
      galaxy-buds-client
      zoom-us
      # teamviewer

      # NOTE: alt+f12 -> View -> Icon Theme
      # NOTE: alt+f12 -> Appearance
      libreoffice-qt6-fresh
    ];

    # required by libreoffice
    programs.java.enable = true;
  };
}
