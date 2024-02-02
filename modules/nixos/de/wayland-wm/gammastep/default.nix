{ config, pkgs, lib, ... }:

let cfg = config._custom.de.gammastep;
in {
  options._custom.de.gammastep.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gammastep ];

    _custom.hm = {
      services.gammastep = {
        enable = true;
        latitude = "-12.051408";
        longitude = "-76.922124";
        temperature = {
          day = 4000;
          night = 3700;
        };
      };
    };
  };
}
