{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.idle;
  inherit (config._custom.globals) userName configDirectory;
  backlight-restore = pkgs.writeScriptBin "backlight-restore" # sh
    (builtins.readFile ./scripts/backlight-restore.sh);
  close-overlays = pkgs.writeScriptBin "close-overlays" # sh
    (builtins.readFile ./scripts/close-overlays.sh);
  dpms = pkgs.writeScriptBin "dpms" # sh
    (builtins.readFile ./scripts/dpms.sh);
in {
  options._custom.desktop.idle.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        wlinhibit # control idle inhibit
        sway-audio-idle-inhibit # complement to swayidle

        backlight-restore
        close-overlays
        dpms

        chayang # gradually dim the screen
        wlopm # toggle screen
      ];

      xdg.configFile."hypr/hypridle.conf".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/hypridle.conf;

      services.hypridle = {
        enable = true;
        settings = { };
      };

      systemd.user.services = {
        sway-audio-idle-inhibit = lib._custom.mkWaylandService {
          Unit = {
            Description =
              "Prevents swayidle from sleeping while any application is outputting or receiving audio.";
            Documentation =
              "https://github.com/ErikReider/SwayAudioIdleInhibit";
            Requires = [ "hypridle.service" ];
            Wants = [ "hypridle.service" ];
            PartOf = [ ];
          };
          Service = {
            ExecStart =
              "${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit";
            Type = "simple";
          };
        };

        hypridle = lib._custom.mkWaylandService {
          Unit.ConditionEnvironment = lib.mkForce "";
        };
      };
    };
  };
}

