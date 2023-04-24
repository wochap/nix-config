{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [ unstable.swww ];
        sessionVariables = {
          SWWW_TRANSITION_TYPE = "simple";
          SWWW_TRANSITION_STEP = "45";
          SWWW_TRANSITION_FPS = "60";
          SWWW_TRANSITION_BEZIER = "0.42,0,0.58,1";
        };
      };

      systemd.user.services.swww-daemon = {
        Unit = {
          Description = "A Solution to your Wayland Wallpaper Woes";
          Documentation = "https://github.com/Horus645/swww";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          PassEnvironment = [
            "SWWW_TRANSITION_TYPE"
            "SWWW_TRANSITION_STEP"
            "SWWW_TRANSITION_FPS"
            "SWWW_TRANSITION_BEZIER"
          ];
          ExecStart = "${pkgs.unstable.swww}/bin/swww-daemon";
          Type = "oneshot";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
      systemd.user.services.swww = {
        Unit = {
          Description = "A Solution to your Wayland Wallpaper Woes";
          Documentation = "https://github.com/Horus645/swww";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          PassEnvironment = [
            "SWWW_TRANSITION_TYPE"
            "SWWW_TRANSITION_STEP"
            "SWWW_TRANSITION_FPS"
            "SWWW_TRANSITION_BEZIER"
          ];
          ExecStart =
            "${pkgs.unstable.swww}/bin/swww img /home/${userName}/Pictures/backgrounds/dracula.jpeg";
          Type = "oneshot";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
