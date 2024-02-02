{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.waylandWm;

  hyprpicker = inputs.hyprpicker.packages.${system}.hyprpicker;

  play-notification-sound = pkgs.writeScriptBin "play-notification-sound"
    (builtins.readFile ./scripts/play-notification-sound.sh);
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        hyprpicker # color picker
        chayang # gradually dim the screen

        slurp # screenshoot utility
        grim # screenshoot utility
        wf-recorder # screen recorder utility
        wl-screenrec # screen recorder utility (faster)
      ];

      etc = {
        "scripts/system/color-picker.sh" = {
          source = ./scripts/color-picker.sh;
          mode = "0755";
        };
        "scripts/system/takeshot.sh" = {
          source = ./scripts/takeshot.sh;
          mode = "0755";
        };
        "scripts/system/recorder.sh" = {
          source = ./scripts/recorder.sh;
          mode = "0755";
        };
      };
    };

    _custom.hm = {
      home.packages = [ play-notification-sound ];
      xdg.dataFile."assets/notification.flac".source =
        ./assets/notification.flac;
    };
  };
}
