{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.labwc;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.de.labwc = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wlopm # toggle screen
      wlrctl # control keyboard, mouse and wm from cli
      bemenu
      foot
      unstable.labwc
    ];

    _custom.de.greetd.cmd = lib.mkIf cfg.isDefault "labwc";
    _custom.de.waybar.systemdEnable = lib.mkIf cfg.isDefault false;

    _custom.hm = lib.mkMerge [
      {
        xdg.configFile."labwc/environment".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/environment;
        xdg.configFile."labwc/rc.xml".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/rc.xml;
        xdg.configFile."labwc/menu.xml".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/menu.xml;
        xdg.configFile."labwc/autostart".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/autostart;
      }

      (lib.mkIf cfg.isDefault {
        home.sessionVariables = {
          XDG_CURRENT_DESKTOP = "wlroots";
          XDG_SESSION_DESKTOP = "labwc";
        };

        services.swayidle.timeouts = lib.mkAfter [
          {
            timeout = 195;
            command = ''wlopm --off "*"'';
            resumeCommand = ''wlopm --on "*"'';
          }
          {
            timeout = 15;
            command = ''if pgrep swaylock; then wlopm --off "*"; fi'';
            resumeCommand = ''if pgrep swaylock; then wlopm --on "*"; fi'';
          }
        ];
      })
    ];
  };
}

