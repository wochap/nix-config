{ config, pkgs, lib, ... }:

let
  customThunar = pkgs.xfce.thunar.override {
    thunarPlugins = [ pkgs.xfce.thunar-archive-plugin ];
  };
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        xfce.thunar-volman # auto mont devices
        customThunar
      ];
    };

    # Systemd services
    systemd.packages = [ customThunar ];
  };
}
