{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  swww-random = pkgs.writeTextFile {
    name = "swww-random";
    destination = "/bin/swww-random";
    executable = true;
    text = builtins.readFile ./scripts/random-bg.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [ swww swww-random ];
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
          ExecStart = "${pkgs.swww}/bin/swww-daemon";
          ExecStop = "${pkgs.swww}/bin/swww kill";
          Type = "oneshot";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
