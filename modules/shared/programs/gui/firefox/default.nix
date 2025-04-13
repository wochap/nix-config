{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.firefox;
in {
  options._custom.programs.firefox.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      imports = [ inputs.arkenfox.hmModules.default ];

      # precise scrolling in Firefox
      home.sessionVariables.MOZ_USE_XINPUT2 = "1";

      home.file = {
        ".mozilla/firefox/default/chrome/userChrome.css".source =
          ./assets/userChrome.css;
        ".mozilla/firefox/default/chrome/customChrome.css".source =
          ./assets/customChrome.css;
        ".mozilla/firefox/default/chrome/userContent.css".text = "";
      };

      programs.firefox = {
        enable = true;
        package =
          (pkgs.firefox.override (old: { cfg = { pipewireSupport = true; }; }));
        arkenfox = {
          enable = true;
          version = "128.0";
        };
        policies = {
          DisableTelemetry = true;
          DisablePocket = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          ExtensionSettings = {
            # Disable built-in search engines
            "amazondotcom@search.mozilla.org" = {
              installation_mode = "blocked";
            };
            "bing@search.mozilla.org" = { installation_mode = "blocked"; };
            "ddg@search.mozilla.org" = { installation_mode = "blocked"; };
            "ebay@search.mozilla.org" = { installation_mode = "blocked"; };
          };
        };
        profiles = {
          default = {
            id = 0;
            name = "default";
            isDefault = true;
            arkenfox = {
              enable = true;
              # docs: https://arkenfox.dwarfmaster.net/
              "0000".enable = true; # disable about:config warning
              # "0100".enable = true; # STARTUP
              "0200".enable = true; # GEOLOCATION / LANGUAGE / LOCALE
              "0300".enable = true; # QUIETER FOX
              "0400".enable = true; # SAFE BROWSING (SB)
              "0600".enable = true; # BLOCK IMPLICIT OUTBOUND
              "0800".enable =
                true; # LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORMS
              "0900".enable = true; # PASSWORDS
              "1200".enable = true; # HTTPS (SSL/TLS / OCSP / CERTS / HPKP)
              "1600".enable = true; # REFERERS
              "1700".enable = true; # CONTAINERS
              "2600".enable = true; # MISCELLANEOUS
              "2700".enable = true; # ETP (ENHANCED TRACKING PROTECTION)
              # "2800".enable = true; # SHUTDOWN & SANITIZING
            };
            settings = {
              "browser.fullscreen.autohide" = false;
              "browser.quitShortcut.disabled" = true;
              "browser.tabs.tabMinWidth" = 5;
              "browser.startup.page" = 3;

              # vertical tabs
              "sidebar.verticalTabs" = true;

              # use native GTK buttons
              "widget.gtk.non-native-titlebar-buttons.enabled" = false;

              # custom scrollbar
              "widget.non-native-theme.scrollbar.size" = 24;

              "widget.use-xdg-desktop-portal.file-picker" = 1;

              # Allow customChrome.css
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

              # Use OS window border
              "browser.tabs.drawInTitlebar" = false;
              "browser.tabs.inTitlebar" = 1;

              # Density compact
              "browser.uidensity" = 1;

              # Disable thumbnail preview ctrl + tab
              "browser.ctrlTab.recentlyUsedOrder" = false;

              # Disable mouseover preview
              "browser.tabs.hoverPreview.enabled" = false;

              "extensions.pocket.enabled" = false;
              "general.smoothScroll" = false;

              # Fix right click
              "ui.context_menus.after_mouseup" = true;

              # Enable video hardware acceleration
              "media.ffmpeg.vaapi.enabled" = true;
              "gfx.webrender.all" = true;
              "media.ffvpx.enabled" = false;

              # https://wiki.archlinux.org/index.php/Firefox/Tweaks#Performance
              # "browser.preferences.defaultPerformanceSettings.enabled" = false;
              # "dom.ipc.processCount" = 8;

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
