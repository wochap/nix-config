{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.cliphist;
  clipboard-manager = pkgs.writeScriptBin "clipboard-manager"
    (builtins.readFile ./scripts/clipboard-manager.sh);
in {
  options._custom.de.cliphist.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        cliphist
        wl-clip-persist
        wl-clipboard
        clipboard-manager
      ];

      systemd.user.services.cliphist = lib._custom.mkWaylandService {
        Unit.Description = "Wayland clipboard manager";
        Unit.Documentation = "https://github.com/sentriz/cliphist";
        Service = {
          PassEnvironment = "PATH";
          ExecStart = "clipboard-manager --start";
          Restart = "on-failure";
          KillMode = "mixed";
        };
      };
    };
  };
}

