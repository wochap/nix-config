{ config, pkgs, lib, inputs, system, ... }:

let cfg = config._custom.programs.others-linux;
in {
  options._custom.programs.others-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      brave
      google-chrome
      microsoft-edge
      inputs.zen-browser.packages."${system}".specific

      galaxy-buds-client

      libreoffice-qt
      # antimicroX # map kb/mouse to gamepad
      # skypeforlinux
      # teamviewer
      # zoom-us
    ];

    # required by libreoffice
    programs.java.enable = true;
  };
}
# Show icons in GTK menus: https://forums.linuxmint.com/viewtopic.php?t=337850
# Change icons: https://www.youtube.com/watch?v=L8CteAuicqY
