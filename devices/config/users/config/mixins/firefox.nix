{ config, pkgs, ... }:

let
  moz-rev = "3f3fba4e2066f28a1ad7ac60e86a688a92eb5b5f";
  moz-url = builtins.fetchTarball { url = "https://github.com/mozilla/nixpkgs-mozilla/archive/${moz-rev}.tar.gz";};
  nightlyOverlay = (import "${moz-url}/firefox-overlay.nix");
in
{
  config = {
    # Install nightly firefox version
    nixpkgs.overlays = [
      nightlyOverlay
    ];

    home-manager.users.gean = {
      home.file = {
        ".mozilla/firefox/default/chrome/userChrome.css".text = ''
          @import "customChrome.css";
        '';
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

          /* Remove round borders of menus/dropdowns */
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
        package = pkgs.latest.firefox-beta-bin;
        profiles = {
          default = {
            id = 0;
            name = "default";
            isDefault = true;
            settings = {
              "browser.tabs.tabMinWidth" = 5;

              # Allow customChrome.css
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

              # Use OS window border
              "browser.tabs.drawInTitlebar" = false;

              # Density compact
              "browser.uidensity" = 1;

              # Disable thumbnail preview ctrl + tab
              "browser.ctrlTab.recentlyUsedOrder" = false;

              # Force webrender
              # "gfx.webrender.all" = true;

              # Force opengl
              # "layers.acceleration.force-enabled" = true;

              # Fix right click
              "ui.context_menus.after_mouseup" = true;

              # Enable video hardware acceleration
              "media.ffmpeg.vaapi.enabled" = true;
              "media.ffvpx.enabled" = false;
              "media.rdd-vpx.enabled" = false;

              # https://wiki.archlinux.org/index.php/Firefox/Tweaks#Performance
              "browser.preferences.defaultPerformanceSettings.enabled" = false;
              "dom.ipc.processCount" = 8;

              # Workaround for when xdg.portal is enabled? set to false
              # https://bugzilla.mozilla.org/show_bug.cgi?id=1618094
              # "network.protocol-handler.external-default" = false;
            };
          };
        };
      };
    };
  };
}
