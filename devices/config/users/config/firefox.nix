

{ config, pkgs, ... }:

let
  firefox-theme = builtins.fetchGit {
    url = "https://github.com/wochap/firefox-theme.git";
    rev = "d465fdf350b2a5b11719de932c9ab42f2671e43f";
    ref = "main";
  };
in
{
  config = {
    home-manager.users.gean = {
      home.file = {
        ".mozilla/firefox/default/chrome".source = "${firefox-theme}/chrome";
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
