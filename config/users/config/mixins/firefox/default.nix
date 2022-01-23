{ config, pkgs, ... }:

let
  userName = config._userName;
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    environment.sessionVariables = {
      # precise scrolling in Firefox
      MOZ_USE_XINPUT2 = "1";
    };

    home-manager.users.${userName} = {
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
          tabs#tabbrowser-tabs {
            --tab-line-color: #44475a !important;
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
          ${builtins.readFile ./assets/jira.css}
        '';
      };
      programs.firefox = {
        enable = true;
        package = if isWayland then pkgs.firefox-bin else pkgs.firefox-wayland;
        profiles = {
          default = {
            id = 0;
            name = "default";
            isDefault = true;
            settings = {
              "browser.quitShortcut.disabled" =  true;
              "browser.tabs.tabMinWidth" = 5;

              # custom scrollbar
              "widget.non-native-theme.scrollbar.size" = 24;

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
              "media.navigator.mediadatadecoder_vpx_enabled" = true;
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

