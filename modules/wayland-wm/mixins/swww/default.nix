{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  swww-random = pkgs.writeTextFile {
    name = "swww-random";
    destination = "/bin/swww-random";
    executable = true;
    text = builtins.readFile ./scripts/swww-random.sh;
  };
  swww-pick = pkgs.writeTextFile {
    name = "swww-pick";
    destination = "/bin/swww-pick";
    executable = true;
    text = builtins.readFile ./scripts/swww-pick.sh;
  };
  inherit (pkgs.unstable) swww;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        symlinks = {
          "${hmConfig.home.homeDirectory}/Pictures/backgrounds" =
            "${hmConfig.home.homeDirectory}/Sync/backgrounds";
        };

        packages = [ swww swww-random swww-pick ];
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
            # "HOME"
            "PATH"
            "XDG_RUNTIME_DIR"
            "SWWW_TRANSITION_TYPE"
            "SWWW_TRANSITION_STEP"
            "SWWW_TRANSITION_FPS"
            "SWWW_TRANSITION_BEZIER"
          ];
          ExecStart = "${swww}/bin/swww init";
          # ExecStartPost = "${swww}/bin/swww img $(${pkgs.coreutils}/bin/cat $HOME/.cache/swww/* | ${pkgs.coreutils}/bin/head -n 1)";
          # ExecStartPost = "${swww-random}/bin/swww-random $HOME/Pictures/backgrounds/";
          ExecStop = "${swww}/bin/swww kill";
          Type = "oneshot";
          RemainAfterExit = true;
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
