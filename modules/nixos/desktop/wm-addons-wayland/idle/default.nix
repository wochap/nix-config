{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.idle;
  inherit (config._custom.globals) configDirectory systemdTarget;
  idle-backlight = pkgs.writeScriptBin "idle-backlight" (
    builtins.readFile ./scripts/idle-backlight.sh
  );
  idle-close-overlays = pkgs.writeScriptBin "idle-close-overlays" (
    builtins.readFile ./scripts/idle-close-overlays.sh
  );
in
{
  options._custom.desktop.idle.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        wlinhibit # control idle inhibit
        wayland-pipewire-idle-inhibit # complement to swayidle
        chayang # gradually dim the screen
        wlopm # toggle screen

        idle-backlight
        idle-close-overlays
      ];

      xdg.configFile."hypr/hypridle.conf".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/hypridle.conf;

      services.hypridle = {
        enable = true;
        settings = { };
        inherit systemdTarget;
      };

      systemd.user.services = {
        wayland-pipewire-idle-inhibit = lib._custom.mkWaylandService {
          Unit = {
            Description = "Inhibit Wayland idling when media is played through pipewire";
            Documentation = "https://github.com/rafaelrc7/wayland-pipewire-idle-inhibit";
            After = [
              "pipewire.service"
              systemdTarget
            ];
            Wants = [ "pipewire.service" ];
          };
          Install.WantedBy = [ systemdTarget ];
          Service = {
            ExecStart = "${lib.getExe pkgs.wayland-pipewire-idle-inhibit}";
            Restart = "always";
            RestartSec = 10;
          }
          // lib._custom.userServiceHardening
          // {
            ProtectHome = "tmpfs";
            RestrictAddressFamilies = [ "AF_UNIX" ];
          };
        };

        hypridle = lib._custom.mkWaylandService { };
      };
    };
  };
}
