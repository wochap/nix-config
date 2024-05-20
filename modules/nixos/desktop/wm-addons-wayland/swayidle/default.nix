{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.swayidle;
  inherit (config._custom.globals) userName;
  matcha = inputs.matcha.packages.${system}.default;
  matcha-toggle-mode = pkgs.writeScriptBin "matcha-toggle-mode"
    (builtins.readFile ./scripts/matcha-toggle-mode.sh);
  matcha-start = let file = "/home/${userName}/tmp/matcha";
  in (pkgs.writeScriptBin "matcha-start" ''
    #!${pkgs.bash}/bin/bash

    ${pkgs.coreutils}/bin/test -f ${file} && ${pkgs.coreutils}/bin/rm ${file}
    ${matcha}/bin/matcha --daemon --off
  '');
in {
  options._custom.desktop.swayidle.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        matcha # control idle inhibit
        matcha-toggle-mode
        sway-audio-idle-inhibit # complement to swayidle
        swayidle

        chayang # gradually dim the screen
        wlopm # toggle screen
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
        timeouts = [
          {
            timeout = 185;
            command = "BACKGROUND=1 swaylock-start";
          }
          {
            timeout = 180;
            command = ''
              if ! pgrep swaylock; then brightnessctl --save && chayang -d 5 && wlopm --off "*"; fi'';
            resumeCommand = ''
              if ! pgrep swaylock; then wlopm --on "*" && brightnessctl --restore; fi'';
          }
          {
            timeout = 15;
            command = ''
              if pgrep swaylock; then brightnessctl --save && wlopm --off "*"; fi'';
            resumeCommand = ''
              if pgrep swaylock; then wlopm --on "*" && brightnessctl --restore; fi'';
          }
        ];
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

        matcha = lib._custom.mkWaylandService {
          Unit = {
            Description = "An Idle Inhibitor for Wayland";
            Documentation = "https://codeberg.org/QuincePie/matcha";
            After = [ "swayidle.service" ];
            Wants = [ "swayidle.service" ];
          };
          Service = {
            Type = "forking";
            PassEnvironment = "PATH";
            ExecStart = "${matcha-start}/bin/matcha-start";
          };
        };
      };
    };
  };
}

