

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
      programs.firefox = {
        enable = true;
        profiles = {
          gean = {
            # user.js
            # extraConfig = (import "${home-manager}/nixos");
            # extraConfig = (builtins.readFile ./dotfiles/config.fish);
            extraConfig = (builtins.readFile "${firefox-theme}/user.js");
            id = 1000;
            isDefault = true;
            name = "gean";
            settings = {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "layers.acceleration.force-enabled" = true;
            };
            userChrome = ".userChrome {}";
            userContent = ".userContent {}";
          };
        };
      };
    };
  };
}
