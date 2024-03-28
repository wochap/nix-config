{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.swww;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  swww-random = pkgs.writeScriptBin "swww-random"
    (builtins.readFile ./scripts/swww-random.sh);
  swww-pick =
    pkgs.writeScriptBin "swww-pick" (builtins.readFile ./scripts/swww-pick.sh);
  inherit (pkgs) swww;
in {
  options._custom.desktop.swww.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
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

      systemd.user.services.swww-daemon = lib._custom.mkWaylandService {
        Unit = {
          Description = "A Solution to your Wayland Wallpaper Woes";
          Documentation = "https://github.com/Horus645/swww";
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
          ExecStop = "${swww}/bin/swww kill";
          Type = "oneshot";
          RemainAfterExit = true;
          KillMode = "mixed";
        };
      };
    };
  };
}
