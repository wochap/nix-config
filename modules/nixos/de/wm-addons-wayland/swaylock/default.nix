{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.swaylock;
  swaylock-start = pkgs.writeScriptBin "swaylock-start"
    (builtins.readFile ./scripts/swaylock-start.sh);
in {
  options._custom.de.swaylock.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: necessary for swaylock to unlock
    security.pam.services.swaylock.text = ''
      auth include login
    '';

    _custom.hm.home.packages = with pkgs; [
      swaylock-effects # lockscreen
      swaylock-start
    ];
  };
}

