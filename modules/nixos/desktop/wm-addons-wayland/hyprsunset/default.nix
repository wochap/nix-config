{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.hyprsunset;
  hyprsunset-final = pkgs.hyprsunset;
in {
  options._custom.desktop.hyprsunset.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ hyprsunset-final ];

    _custom.hm = {
      services.hyprsunset = {
        enable = true;
        package = hyprsunset-final;
        transitions = {
          sunrise = {
            calendar = "*-*-* 06:00:00";
            requests = [[ "temperature" "4000" ]];
          };
          sunset = {
            calendar = "*-*-* 18:00:00";
            requests = [[ "temperature" "3700" ]];
          };
        };
      };

      # only start hyprsunset on wayland wm
      systemd.user.services.hyprsunset.Unit.ConditionEnvironment =
        lib.mkForce "XDG_SESSION_DESKTOP=hyprland";
    };
  };
}
