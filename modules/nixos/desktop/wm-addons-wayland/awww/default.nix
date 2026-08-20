{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.awww;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  awww-random = pkgs.writeScriptBin "awww-random" (builtins.readFile ./scripts/awww-random.sh);
  awww-pick = pkgs.writeScriptBin "awww-pick" (builtins.readFile ./scripts/awww-pick.sh);
  awww-kansallisgalleria = pkgs.writeScriptBin "awww-kansallisgalleria" (
    builtins.readFile ./scripts/awww-kansallisgalleria.sh
  );
  awww-unsplash = pkgs.writeScriptBin "awww-unsplash" (builtins.readFile ./scripts/awww-unsplash.sh);
  inherit (pkgs) awww;
in
{
  options._custom.desktop.awww.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        symlinks = {
          "${hmConfig.home.homeDirectory}/Pictures/backgrounds" =
            "${hmConfig.home.homeDirectory}/Sync/backgrounds";
        };

        packages = [
          awww
          awww-random
          awww-pick
          awww-kansallisgalleria
          awww-unsplash
        ];
        sessionVariables = {
          AWWW_TRANSITION = "simple";
          AWWW_TRANSITION_TYPE = "simple";
          AWWW_TRANSITION_STEP = "45";
          AWWW_TRANSITION_FPS = "60";
          AWWW_TRANSITION_BEZIER = "0.42,0,0.58,1";
        };
      };

      systemd.user.services.awww-daemon = lib._custom.mkWaylandService {
        Unit = {
          Description = "A Solution to your Wayland Wallpaper Woes";
          Documentation = "https://codeberg.org/LGFae/awww";
        };
        Service = {
          PassEnvironment = [
            "AWWW_TRANSITION"
            "AWWW_TRANSITION_TYPE"
            "AWWW_TRANSITION_STEP"
            "AWWW_TRANSITION_FPS"
            "AWWW_TRANSITION_BEZIER"
          ];
          ExecStart = "${awww}/bin/awww-daemon";
          ExecStop = "${awww}/bin/awww kill";
          Type = "oneshot";
          RemainAfterExit = true;
          KillMode = "mixed";
        };
      };
    };
  };
}
