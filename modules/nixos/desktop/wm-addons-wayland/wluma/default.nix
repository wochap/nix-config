{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.wluma;
  wluma-backlight = pkgs.writeTextFile {
    name = "90-wluma-backlight.rules";
    text = builtins.replaceStrings [ "/bin/chgrp" "/bin/chmod" ] [
      "${pkgs.coreutils}/bin/chgrp"
      "${pkgs.coreutils}/bin/chmod"
    ] (builtins.readFile "${inputs.wluma}/90-wluma-backlight.rules");
    destination = "/etc/udev/rules.d/90-wluma-backlight.rules";
  };
  tomlFormat = pkgs.formats.toml { };
in {
  options._custom.desktop.wluma = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
    config = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          "als.none" = { };
          "output.backlight" = [{
              name = "eDP-1";
              path = "/sys/class/backlight/amdgpu_bl1";
              capturer = "wlroots";
          }];
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.packages = [ wluma-backlight ];

    _custom.hm = {
      home.packages = with pkgs; [ wluma ];

      xdg.configFile."wluma/config.toml".source =
        tomlFormat.generate "config.toml" cfg.config;

      systemd.user.services.wluma = lib.mkIf cfg.systemdEnable
        (lib._custom.mkWaylandService {
          Unit = {
            Description =
              "Adjusting screen brightness based on screen contents and amount of ambient light";
            Documentation = "https://github.com/maximbaz/wluma";
          };
          Service = {
            ExecStart = "${pkgs.wluma}/bin/wluma";
            PrivateNetwork = true;
            PrivateMounts = false;
            Restart = "always";
            RestartSec = 1;
            EnvironmentFile = "-%E/wluma/service.conf";
          };
        });
    };
  };
}
