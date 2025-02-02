{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.wayland-utils;

  wayfreeze = inputs.wayfreeze.packages.${system}.wayfreeze;
  hyprpicker = inputs.hyprpicker.packages.${system}.hyprpicker;
  play-notification-sound = pkgs.writeScriptBin "play-notification-sound"
    (builtins.readFile ./scripts/play-notification-sound.sh);
  color-picker = pkgs.writeScriptBin "color-picker"
    (builtins.readFile ./scripts/color-picker.sh);
  ruler = pkgs.writeScriptBin "ruler" (builtins.readFile ./scripts/ruler.sh);
  takeshot =
    pkgs.writeScriptBin "takeshot" (builtins.readFile ./scripts/takeshot.sh);
  ocr = pkgs.writeScriptBin "ocr" (builtins.readFile ./scripts/ocr.sh);
  recorder =
    pkgs.writeScriptBin "recorder" (builtins.readFile ./scripts/recorder.sh);
  tui-bookmarks = pkgs.writeScriptBin "tui-bookmarks"
    (builtins.readFile ./scripts/tui-bookmarks.sh);
  tui-calendar = pkgs.writeScriptBin "tui-calendar"
    (builtins.readFile ./scripts/tui-calendar.sh);
  tui-email =
    pkgs.writeScriptBin "tui-email" (builtins.readFile ./scripts/tui-email.sh);
  tui-monitor = pkgs.writeScriptBin "tui-monitor"
    (builtins.readFile ./scripts/tui-monitor.sh);
  tui-music =
    pkgs.writeScriptBin "tui-music" (builtins.readFile ./scripts/tui-music.sh);
  tui-notes =
    pkgs.writeScriptBin "tui-notes" (builtins.readFile ./scripts/tui-notes.sh);
  tui-notification-center = pkgs.writeScriptBin "tui-notification-center"
    (builtins.readFile ./scripts/tui-notification-center.sh);
  tui-rss =
    pkgs.writeScriptBin "tui-rss" (builtins.readFile ./scripts/tui-rss.sh);
in {
  options._custom.desktop.wayland-utils.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        showmethekey = prev.showmethekey.overrideAttrs (oldAttrs: rec {
          version = "v1.15.1";
          src = prev.fetchFromGitHub {
            owner = "AlynxZhou";
            repo = "showmethekey";
            rev = version;
            hash = "sha256-odlIgWFmhDqju7U5Y9q6apUEAqZUvMUA7/eU7LMltQs=";
          };
          patches = [ ./patches/showmethekey-remove-header.patch ];
        });

        slurp = prev.slurp.overrideAttrs (oldAttrs: rec {
          version = "0616010cbc74e79368f75a220cc4eb7a6116dcd0";
          src = prev.fetchFromGitHub {
            owner = "emersion";
            repo = "slurp";
            rev = version;
            hash = "sha256-/ntSVJ+HfdM6mHKYwR6zijClkBP0eZg7oVZL6/QqNMo=";
          };
        });
      })
    ];

    _custom.hm = {
      home.packages = with pkgs; [
        grim # screenshoot utility
        hyprpicker # color picker
        showmethekey
        slurp # screenshoot utility
        swappy # minimal image editor
        swaybg
        wayfreeze # freeze display, only works on hyprland
        wdisplays # control display outputs
        wf-recorder # screen recorder utility
        wl-mirror # mirror outputs
        wl-screenrec # screen recorder utility (faster)
        wlr-randr
        wlrctl # control keyboard, mouse and wm from cli
        tesseract5 # ocr
        cage # wm

        play-notification-sound
        color-picker
        ruler
        recorder
        takeshot
        ocr

        tui-bookmarks
        tui-calendar
        tui-email
        tui-monitor
        tui-music
        tui-notes
        tui-notification-center
        tui-rss
      ];

      home.shellAliases."cpi" = ''wl-copy -t text/uri-list <<<file:/"$@"'';

      xdg.configFile."swappy/config".source = ./dotfiles/swappy-config;
      xdg.dataFile."assets/notification.flac".source =
        ./assets/notification.flac;
    };
  };
}
