

{ config, pkgs, ... }:

let
  firefox-theme = builtins.fetchGit {
    url = "https://github.com/wochap/firefox-theme.git";
    rev = "d5528ff0315b10d256eeb651caadbaac667fea67";
    ref = "main";
  };
in
{
  config = {
    home-manager.users.gean = {
      home.file = {
        ".mozilla/firefox/default/chrome/userChrome.css".source = "${firefox-theme}/chrome/userChrome.css";
        ".mozilla/firefox/default/chrome/WhiteSur".source = "${firefox-theme}/chrome/WhiteSur";
      };
      programs.firefox = {
        enable = true;
        profiles = {
          default = {
            extraConfig = (builtins.readFile "${firefox-theme}/user.js");
            id = 0;
            name = "default";
            isDefault = true;
            settings = {
              "browser.tabs.tabMinWidth" = 5;
              "ui.context_menus.after_mouseup" = true;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "layers.acceleration.force-enabled" = true;
            };
          };
        };
      };
    };
  };
}
