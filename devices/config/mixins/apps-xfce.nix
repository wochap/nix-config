{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      glib # gio

      xfce.exo
      (xfce.thunar.override {
        thunarPlugins = [
          xfce.thunar-archive-plugin
        ];
      })
      xfce.thunar # file manager
      xfce.thunar-volman # auto mont devices
      xfce.xfconf # where thunar settings are saved
    ];

    # Required by thunar
    # services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.gvfs.package = pkgs.xfce.gvfs;
    services.tumbler.enable = true;
  };
}
