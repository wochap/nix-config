{ config, lib, ... }:

let cfg = config._custom.services.waydroid;
in {
  options._custom.services.waydroid.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # Additional configurations, notes and post-installation steps
    # in https://nixos.wiki/wiki/WayDroid
    virtualisation = {
      waydroid.enable = true;
      lxd.enable = true;
    };

    _custom.user.extraGroups = [ "lxc" ];
  };
}
