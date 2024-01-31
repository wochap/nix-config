{ config, pkgs, lib, ... }:

let
  cfg = config._custom.gui.firefox;
  isWayland = config._custom.globals.displayServer == "wayland";
in {
  options._custom.gui.firefox = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      # Force firefox to use wayland
      MOZ_ENABLE_WAYLAND = lib.mkIf isWayland "1";

      # precise scrolling in Firefox
      MOZ_USE_XINPUT2 = "1";
    };

    _custom.hm = {
      home.file = {
        ".mozilla/firefox/default/chrome/userChrome.css".source =
          ./assets/userChrome.css;
        ".mozilla/firefox/default/chrome/customChrome.css".source =
          ./assets/customChrome.css;
        ".mozilla/firefox/default/chrome/userContent.css".text = "";
      };
      programs.firefox = {
        enable = true;
        package = if isWayland then pkgs.firefox-wayland else pkgs.firefox-bin;
        profiles = {
          default = {
            id = 0;
            name = "default";
            isDefault = true;
            settings = lib.mkMerge [{
              "browser.fullscreen.autohide" = false;
              "browser.quitShortcut.disabled" = true;
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

              "extensions.pocket.enabled" = false;
              "general.smoothScroll" = false;

              # Force opengl
              # "layers.acceleration.force-enabled" = true;

              # Fix right click
              "ui.context_menus.after_mouseup" = true;

              # Enable video hardware acceleration
              # "media.ffmpeg.vaapi.enabled" = true;
              # "media.ffvpx.enabled" = false;
              # "media.navigator.mediadatadecoder_vpx_enabled" = true;
              # "media.rdd-vpx.enabled" = false;

              # https://wiki.archlinux.org/index.php/Firefox/Tweaks#Performance
              # "browser.preferences.defaultPerformanceSettings.enabled" = false;
              # "dom.ipc.processCount" = 8;

              # Workaround for when xdg.portal is enabled? set to false
              # https://bugzilla.mozilla.org/show_bug.cgi?id=1618094
              # "network.protocol-handler.external-default" = false;
            }];
          };
        };
      };
    };
  };
}
