{ config, pkgs, lib, ... }:

let cfg = config._custom.services.kdeconnect;
in {
  options._custom.services.kdeconnect.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    programs.kdeconnect = {
      enable = true;
      package = lib.mkIf config._custom.desktop.gnome.enable
        pkgs.gnomeExtensions.gsconnect;
    };

    _custom.hm = {
      services.kdeconnect = {
        enable = true;
        indicator = false;
      };
    };
  };
}
