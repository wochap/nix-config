{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.programs.others-linux;

  # pseintDesktopItem = (pkgs.makeDesktopItem {
  #   name = "PSeint";
  #   exec = "${pkgs._custom.pseint}/opt/pseint/pseint";
  #   icon = "pseint";
  #   desktopName = "PSeint";
  #   categories = [ "Development" ];
  # });
in {
  options._custom.programs.others-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      brave
      prevstable-chrome.google-chrome
      prevstable-msedge.microsoft-edge
      inputs.zen-browser.packages."${system}".beta

      galaxy-buds-client

      libreoffice-qt
      # antimicroX # map kb/mouse to gamepad
      # skypeforlinux
      # teamviewer
      zoom-us

      # pseintDesktopItem
      # _custom.pseint
    ];

    # required by libreoffice
    programs.java.enable = true;
  };
}
# Show icons in GTK menus: https://forums.linuxmint.com/viewtopic.php?t=337850
# Change icons: https://www.youtube.com/watch?v=L8CteAuicqY
