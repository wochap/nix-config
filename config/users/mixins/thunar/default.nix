{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        pkgs.xfce.thunar-archive-plugin
        xfce.thunar-media-tags-plugin
      ];
    };

    environment = {
      systemPackages = with pkgs;
        [
          xfce.thunar-volman # auto mont devices
        ];
    };

    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images

    home-manager.users.${userName} = {
      xdg.configFile = { "Thunar/uca.xml".source = ./dotfiles/Thunar/uca.xml; };
    };
  };
}
