{ config, pkgs, lib, ... }:

let
  inherit (config._custom.globals) configDirectory;
  cfg = config._custom.programs.thunar;
  plugins = with pkgs; [
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    xfce.thunar-volman # auto mont devices
  ];
  thunar-final = pkgs.xfce.thunar.override { thunarPlugins = plugins; };
in {
  options._custom.programs.thunar.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      inherit plugins;
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
      xdg.configFile."Thunar/uca.xml".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/Thunar/uca.xml;

      xdg.desktopEntries.thunar = {
        name = "Thunar File Manager";
        exec = "Thunar %U";
      };

      xdg.mimeApps = {
        defaultApplications = { "inode/directory" = [ "thunar.desktop" ]; };
        associations.added = { "inode/directory" = [ "thunar.desktop" ]; };
      };

      # fast thunar
      systemd.user.services.thunar-server = lib._custom.mkWaylandService {
        Unit.Description = "Thunar file manager";
        Service = {
          Type = "simple";
          ExecStart = "${thunar-final}/bin/Thunar --daemon";
          KillMode = "process";
        };
      };
    };
  };
}
