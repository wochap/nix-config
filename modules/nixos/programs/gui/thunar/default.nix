{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.thunar;
in {
  options._custom.programs.thunar.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        pkgs.xfce.thunar-archive-plugin
        xfce.thunar-media-tags-plugin
        xfce.thunar-volman # auto mont devices
      ];
    };

    environment = {
      systemPackages = with pkgs; [

        # required by tumbler service
        # TODO: add https://gitlab.com/hxss-linux/folderpreview
        ffmpegthumbnailer # videos
        freetype # fonts
        gdk-pixbuf # images
        libgepub # .epub
        libgsf # .odf
        poppler # .pdf .ps
        webp-pixbuf-loader # .webp
      ];
    };

    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.gvfs.package = pkgs.gnome.gvfs;
    services.tumbler.enable = true; # Thumbnail support for images

    _custom.hm = {
      xdg.configFile = { "Thunar/uca.xml".source = ./dotfiles/Thunar/uca.xml; };
    };
  };
}
