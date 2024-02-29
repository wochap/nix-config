{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.de.wayland-utils;

  hyprpicker = inputs.hyprpicker.packages.${system}.hyprpicker;
  play-notification-sound = pkgs.writeScriptBin "play-notification-sound"
    (builtins.readFile ./scripts/play-notification-sound.sh);
  color-picker = pkgs.writeScriptBin "color-picker"
    (builtins.readFile ./scripts/color-picker.sh);
  takeshot =
    pkgs.writeScriptBin "takeshot" (builtins.readFile ./scripts/takeshot.sh);
  recorder =
    pkgs.writeScriptBin "recorder" (builtins.readFile ./scripts/recorder.sh);
in {
  options._custom.de.wayland-utils.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        showmethekey = prev.showmethekey.overrideAttrs (oldAttrs: {
          version = "6204cf1d4794578372c273348daa342589479b13";
          src = prev.fetchFromGitHub {
            owner = "AlynxZhou";
            repo = "showmethekey";
            rev = "6204cf1d4794578372c273348daa342589479b13";
            hash = "sha256-eeObomb4Gv/vpvViHsi3+O0JR/rYamrlZNZaXKL6KJw=";
          };
          buildInputs = oldAttrs.buildInputs ++ [ prev.libadwaita ];
        });
      })
    ];

    _custom.hm = {
      home.packages = with pkgs; [
        swappy # minimal image editor
        hyprpicker # color picker
        chayang # gradually dim the screen
        slurp # screenshoot utility
        grim # screenshoot utility
        wf-recorder # screen recorder utility
        wl-screenrec # screen recorder utility (faster)
        play-notification-sound
        recorder
        takeshot
        color-picker
        showmethekey
        wdisplays # control display outputs
        wlr-randr
        swaybg
      ];

      xdg.configFile."swappy/config".source = ./dotfiles/swappy-config;
      xdg.dataFile."assets/notification.flac".source =
        ./assets/notification.flac;
    };
  };
}
