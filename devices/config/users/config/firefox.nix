

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
        ".mozilla/firefox/default/chrome/customChrome.css".text = ''
          /* Remove Tab outline */
          .keyboard-focused-tab > .tab-stack > .tab-content,
          .tabbrowser-tab:focus:not([aria-activedescendant]) > .tab-stack > .tab-content {
            outline: 0 !important;
          }

          /* Remove Findbar transition */
          findbar {
            transition: none !important;
          }

          menupopup {
            border-radius: 0 !important;
          }
        '';
        ".mozilla/firefox/default/chrome/userContent.css".text = ''
          /* Custom scrollbar */
          * {
            scrollbar-width: auto;
            scrollbar-color: #58a6ff transparent;
          }
        '';
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

              # Force webrender
              "gfx.webrender.all" = false;

              # Force opengl
              "layers.acceleration.force-enabled" = false;

              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "ui.context_menus.after_mouseup" = true;

              # Enable video hardware acceleration
              "media.ffmpeg.vaapi.enabled" = true;
              "media.ffvpx.enabled" = false;
              "media.rdd-vpx.enabled" = false;

              # https://wiki.archlinux.org/index.php/Firefox/Tweaks#Performance
              "browser.preferences.defaultPerformanceSettings.enabled" = false;
              "dom.ipc.processCount" = 8;
            };
          };
        };
      };
    };
  };
}
