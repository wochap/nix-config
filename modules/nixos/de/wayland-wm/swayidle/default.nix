{ config, pkgs, lib, ... }:

let cfg = config._custom.de.swayidle;
in {
  options._custom.de.swayidle.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        swayidle
        sway-audio-idle-inhibit # complement to swayidle
      ];

      services.swayidle = {
        enable = true;
        systemdTarget = "wayland-session.target";
        events = [
          {
            event = "before-sleep";
            command = "swaylock-start";
          }
          {
            event = "lock";
            command = "swaylock-start";
          }
        ];
        timeouts = [{
          timeout = 180;
          command = "swaylock-start";
        }];
      };

      systemd.user.services = {
        swayidle.Service = {
          Environment = lib.mkForce "";
          PassEnvironment = "PATH";
        };

        sway-audio-idle-inhibit = lib._custom.mkWaylandService {
          Unit = {
            Description =
              "Prevents swayidle from sleeping while any application is outputting or receiving audio.";
            Documentation =
              "https://github.com/ErikReider/SwayAudioIdleInhibit";
            After = [ "swayidle.service" ];
            Wants = [ "swayidle.service" ];
          };
          Service = {
            PassEnvironment = "PATH";
            ExecStart =
              "${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit";
            Type = "simple";
          };
        };
      };
    };
  };
}

