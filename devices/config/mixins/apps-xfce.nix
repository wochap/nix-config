{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      glib # for gsettings
      xfce.exo # needed for open terminal here to function
      xfce.thunar-volman # auto mont devices
      xfce.xfconf # where thunar settings are saved
      (xfce.thunar.override {
        thunarPlugins = [
          xfce.thunar-archive-plugin
        ];
      })
    ];

    # Required by thunar
    # services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.gvfs.package = lib.mkForce pkgs.gnome3.gvfs;
    services.tumbler.enable = true;
  };
}
