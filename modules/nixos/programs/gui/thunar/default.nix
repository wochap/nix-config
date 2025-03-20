{ config, pkgs, lib, ... }:

let
  inherit (config._custom.globals) configDirectory;
  cfg = config._custom.programs.thunar;
  plugins = with pkgs; [
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    xfce.thunar-volman # auto mont devices
  ];
  finalThunar = pkgs.xfce.thunar.override { thunarPlugins = plugins; };
in {
  options._custom.programs.thunar.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        xfce = prev.lib.recursiveUpdate prev.xfce {
          thunar = prev.xfce.thunar.overrideAttrs (oldAttrs: rec {
            src = pkgs.fetchFromGitHub {
              owner = "wochap";
              repo = "thunar";
              rev = "xfce-4.18-hide-menu-btn-b";
              sha256 = "sha256-3Fu7KBwom5+wf896x6r0ixldqguX6fCXXUEOgGcrx+Y=";
            };
            # patches = [
            #   # removes toolbar toggle button
            #   # press Ctrl+m to toggle toolbar
            #   # patch works on thunar 4.18
            #   (pkgs.fetchpatch {
            #     url =
            #       "https://github.com/wochap/thunar/commit/906bbc2a30b32cfe8c36a4f1c7f7bff354c98c90.patch";
            #     sha256 = "sha256-RuHWBsGooo/BuHYlmYP6BhttmUMHOc334Y4v1/kEC/8=";
            #   })
            # ];
          });
        };
      })
    ];

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
        Unit = {
          Description = "Thunar file manager";
          Documentation = "man:Thunar(1)";
        };
        Service = {
          Type = "simple";
          ExecStart = "${finalThunar}/bin/Thunar --daemon";
          KillMode = "process";
        };
      };
    };
  };
}
