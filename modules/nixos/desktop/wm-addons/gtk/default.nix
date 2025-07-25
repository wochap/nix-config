{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.gtk;
  inherit (config._custom) globals;
  inherit (globals) userName configDirectory;
  hmConfig = config.home-manager.users.${userName};

  libadwaitaWithoutAdwaitaAurRepo = pkgs.fetchgit {
    url = "https://aur.archlinux.org/libadwaita-without-adwaita-git.git";
    rev = "312880664a0b37402a93d381c9465967d142284a";
    hash = "sha256-Z8htdlLBz9vSiv5qKpCLPoFqk14VTanaLpn+mBITq3o=";
  };
  extraCss = lib.concatLines [
    ''
      /* Palette */
      @import url("file://${hmConfig.xdg.configHome}/theme-colors.css");
      @import url("file://${
        lib._custom.relativeSymlink configDirectory
        ./dotfiles/gtk-theme-catppuccin.css
      }");
    ''

    (lib.optionalString (!cfg.enableCsd) ''
      @import url("file://${
        lib._custom.relativeSymlink configDirectory
        ./dotfiles/gtk-remove-csd.css
      }");
    '')
  ];
in {
  options._custom.desktop.gtk = {
    enable = lib.mkEnableOption { };
    enableCsd = lib.mkEnableOption { };
    enableTheme = lib.mkEnableOption { };
    enableLibadwaitaWithoutAdwaita = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        dconf-editor
        nwg-look

        # gtk deps
        glib # for gsettings program
        gtk3 # for gtk-launch program
        gtk4
        gsettings-desktop-schemas

        # gtk themes
        globals.gtkTheme.package
        globals.gtkIconTheme.package
        whitesur-gtk-theme
        gnome-themes-extra
        whitesur-icon-theme
        numix-icon-theme-circle
        numix-icon-theme-square
        tela-icon-theme
        xfce.xfce4-icon-theme
        reversal-icon-theme
        adwaita-icon-theme
        hicolor-icon-theme
      ];

      # NOTE: can't move it to home-manager because of a conflict
      sessionVariables.XDG_DATA_DIRS = with pkgs; [
        "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
        "${gtk3}/share/gsettings-schemas/${gtk3.name}"
      ];
    };

    # Enable GDK Pixbuf to load SVG icons, essential for many modern icon themes.
    programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

    # Enable the dconf service, required for GSettings to work properly
    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    # Setup libadwaita without adwaita
    nixpkgs.overlays = lib.mkIf cfg.enableLibadwaitaWithoutAdwaita [
      (final: prev: {
        libadwaita-without-adwaita = prev.libadwaita.overrideAttrs (oldAttrs: {
          doCheck = false;
          patches = (oldAttrs.patches or [ ])
            ++ [ "${libadwaitaWithoutAdwaitaAurRepo}/theming_patch.diff" ];
          mesonFlags = (oldAttrs.mesonFlags or [ ])
            ++ [ "--buildtype=release" "-Dexamples=false" ];
        });
      })
    ];
    system.replaceDependencies.replacements = with pkgs;
      lib.mkIf cfg.enableLibadwaitaWithoutAdwaita [{
        oldDependency = libadwaita.out;
        newDependency = libadwaita-without-adwaita.out;
      }];

    _custom.hm = {
      home.sessionVariables = lib.mkMerge [
        {
          # Hide dbus errors in GTK apps?
          NO_AT_BRIDGE = "1";
        }
        (lib.mkIf cfg.enableCsd {
          # https://wiki.gnome.org/Initiatives/CSD
          GTK_CSD = "1";
        })
      ];

      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";

        # Hide window buttons from CSD applications (e.g., Nautilus).
        "org/gnome/desktop/wm/preferences".button-layout = "";

        # Open GTK inspector with Ctrl + Shift + D
        # GTK_DEBUG=interactive <app>
        "org/gtk/Settings/Debug".enable-inspector-keybinding = true;
      };

      # Prevent home-manager service to fail
      # https://discourse.nixos.org/t/way-to-automatically-override-home-manager-collisions/33038/3
      xdg.configFile = {
        "gtk-4.0/gtk.css".force = true;
        "gtk-4.0/settings.ini".force = true;
        "gtk-3.0/gtk.css".force = true;
        "gtk-3.0/settings.ini".force = true;
      };
      gtk = {
        enable = cfg.enableTheme;
        font = {
          name = globals.fonts.sans;
          inherit (globals.fonts) size;
        };
        iconTheme = { inherit (globals.gtkIconTheme) name package; };
        theme = { inherit (globals.gtkTheme) name package; };
        gtk3 = {
          inherit extraCss;
          extraConfig = {
            gtk-xft-antialias = 1;
            gtk-xft-hinting = 1;
            gtk-xft-hintstyle = "hintfull";
          };
          bookmarks = [
            "file://${hmConfig.home.homeDirectory}/Downloads"
            "file://${hmConfig.home.homeDirectory}/Pictures"
            "file://${hmConfig.home.homeDirectory}/Videos"
            "file://${hmConfig.home.homeDirectory}/nix-config"
            "file://${hmConfig.home.homeDirectory}/Projects"
            "file://${hmConfig.home.homeDirectory}/Projects/boc"
            "file://${hmConfig.home.homeDirectory}/Videos/Recordings"
            "file://${hmConfig.home.homeDirectory}/Pictures/Screenshots"
            "file://${hmConfig.home.homeDirectory}/Sync"
          ];
        };
        gtk4.extraCss = extraCss;
      };
    };
  };
}
