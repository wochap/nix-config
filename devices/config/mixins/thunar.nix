{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      # sessionVariables = {
      #   OPENER = "exo-open";
      # };
      systemPackages = with pkgs; [
        glib # for gsettings?
        xfce.exo # opener exo-open
        xfce.thunar-volman # auto mont devices
        xfce.xfconf # where thunar settings are saved
        (xfce.thunar.override {
          thunarPlugins = [
            xfce.thunar-archive-plugin
          ];
        })
      ];
    };

    # Required by thunar
    services.gvfs.enable = true;
    services.gvfs.package = lib.mkForce pkgs.gnome.gvfs;
    services.tumbler.enable = true;
  };
}
