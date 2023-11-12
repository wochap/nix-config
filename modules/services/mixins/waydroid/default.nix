{ config, pkgs, lib, ... }:

let cfg = config._custom.waydroid;
in {
  options._custom.waydroid = { enable = lib.mkEnableOption "enable waydroid"; };

  config = lib.mkIf cfg.enable {
    # source: https://nixos.wiki/wiki/WayDroid 
    virtualisation = {
      waydroid.enable = true;
      lxd.enable = true;
    };
  };
}
