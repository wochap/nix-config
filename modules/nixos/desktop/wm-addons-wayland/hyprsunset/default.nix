{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.hyprsunset;
  inherit (config._custom.globals) configDirectory;
  hyprsunset-final = inputs.hyprsunset.packages.${pkgs.system}.hyprsunset;
in {
  options._custom.desktop.hyprsunset.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ hyprsunset-final ];

    _custom.hm = {
      xdg.configFile."hypr/hyprsunset.conf".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/hyprsunset.conf;

      systemd.user.services.hyprsunset = lib._custom.mkWaylandService {
        Service = {
          ExecStart = "${lib.getExe hyprsunset-final} --temperature 4000";
          Restart = "on-failure";
          KillMode = "mixed";
        };
      };
    };
  };
}
