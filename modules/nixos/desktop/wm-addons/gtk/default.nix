{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.gtk;
  inherit (config._custom) globals;
  inherit (globals)
    userName configDirectory themeColorsLight themeColorsDark preferDark;
  hmConfig = config.home-manager.users.${userName};

  # source: https://aur.archlinux.org/packages/libadwaita-without-adwaita-git
  libadwaitaWithoutAdwaitaAurRepo = pkgs.fetchgit {
    url = "https://aur.archlinux.org/libadwaita-without-adwaita-git.git";
    rev = "d98b5bc68b2eba95104ee36661af788701f43219";
    hash = "sha256-a2yzF9kqycEo44Hmy/Tg+c2UpONiOiU/7KAnCMdpTFY=";
  };
  catppuccin-adw-light-theme-path =
    "${inputs.catppuccin-adw}/adw/themes/${themeColorsLight.flavour}/catppuccin-${themeColorsLight.flavour}-${globals.gtkTheme.accent}.css";
  catppuccin-adw-dark-theme-path =
    "${inputs.catppuccin-adw}/adw/themes/${themeColorsDark.flavour}/catppuccin-${themeColorsDark.flavour}-${globals.gtkTheme.accent}.css";
  extraCssLight = lib.concatLines [
    ''
      /* Palette */
      @import url("file://${
        lib._custom.relativeSymlink configDirectory ./dotfiles/gtk-custom.css
      }");
    ''
    (lib.optionalString (!cfg.enableCsd) ''
      @import url("file://${
        lib._custom.relativeSymlink configDirectory
        ./dotfiles/gtk-remove-csd.css
      }");
    '')
  ];
  # NOTE: looks like gtk3/4 doesn't support this
  extraCssDark = lib.concatLines [
    ''
      /* Palette */
      @import url("file://${
        lib._custom.relativeSymlink configDirectory ./dotfiles/gtk-custom.css
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
    # Setup libadwaita without adwaita
    # so we can change gtk4 theme via gsettings, etc
    nixpkgs.overlays = lib.mkIf cfg.enableLibadwaitaWithoutAdwaita [
      (final: prev: {
        libadwaita-without-adwaita = prev.libadwaita.overrideAttrs (oldAttrs: {
          doCheck = false;
          patches = (oldAttrs.patches or [ ])
            ++ [ "${libadwaitaWithoutAdwaitaAurRepo}/theming_patch.diff" ];
          mesonFlags = (oldAttrs.mesonFlags or [ ])
            ++ [ "--buildtype=release" "-Dexamples=false" ];
        });

        # HACK: inject catppuccin dark/light themes directly into the pkg
        # TODO: fix selected items text contrast
        # @define-color accent_bg_color mix(@mauve, @base, 0.75);
        # @define-color accent_color @mauve;
        adw-gtk3 = prev.adw-gtk3.overrideAttrs (oldAttrs: {
          version = "catppuccin-6.2";
          src = pkgs.fetchFromGitHub {
            owner = "lassekongo83";
            repo = "adw-gtk3";
            tag = "v6.2";
            hash = "sha256-YYaqSEnIYHHkY4L3UhFBkR3DehoB6QADhSGOP/9NKx8=";
          };
          nativeBuildInputs = with pkgs; [ meson ninja dart-sass ];
          postPatch = "";
          postInstall = ''
            echo "Appending Catppuccin styles to final theme files..."

            local lightCssSource="${catppuccin-adw-light-theme-path}"
            local darkCssSource="${catppuccin-adw-dark-theme-path}"

            # Append light theme styles
            cat "$lightCssSource" >> "$out/share/themes/adw-gtk3/gtk-3.0/gtk.css"
            cat "$lightCssSource" >> "$out/share/themes/adw-gtk3/gtk-4.0/gtk.css"

            # Append dark theme styles
            cat "$darkCssSource" >> "$out/share/themes/adw-gtk3/gtk-3.0/gtk-dark.css"
            cat "$darkCssSource" >> "$out/share/themes/adw-gtk3/gtk-4.0/gtk-dark.css"
            cat "$darkCssSource" >> "$out/share/themes/adw-gtk3-dark/gtk-3.0/gtk.css"
            cat "$darkCssSource" >> "$out/share/themes/adw-gtk3-dark/gtk-4.0/gtk.css"
            cat "$darkCssSource" >> "$out/share/themes/adw-gtk3-dark/gtk-3.0/gtk-dark.css"
            cat "$darkCssSource" >> "$out/share/themes/adw-gtk3-dark/gtk-4.0/gtk-dark.css"

            echo "✅ Successfully applied Catppuccin themes."
          '';
        });
      })
    ];
    system.replaceDependencies.replacements = with pkgs;
      lib.mkIf cfg.enableLibadwaitaWithoutAdwaita [{
        oldDependency = libadwaita.out;
        newDependency = libadwaita-without-adwaita.out;
      }];

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

    _custom.hm = {
      home.sessionVariables = lib.mkMerge [
        {
          # Hide dbus errors in GTK apps?
          NO_AT_BRIDGE = "1";

          # TODO: do we need this?
          # ADW_DISABLE_PORTAL = "1";
        }
        (lib.mkIf cfg.enableCsd {
          # https://wiki.gnome.org/Initiatives/CSD
          GTK_CSD = "1";
        })
      ];

      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme =
          if preferDark then "prefer-dark" else "default";

        # Hide window buttons from CSD applications (e.g., Nautilus).
        "org/gnome/desktop/wm/preferences".button-layout = "";

        # Open GTK inspector with Ctrl + Shift + D
        # GTK_DEBUG=interactive <app>
        "org/gtk/Settings/Debug".enable-inspector-keybinding = true;
      };

      # Prevent home-manager service to fail
      # https://discourse.nixos.org/t/way-to-automatically-override-home-manager-collisions/33038/3
      xdg.configFile = {
        # prevent hm from adding gtk-theme contents into gtk4 css
        "gtk-4.0/gtk.css" = {
          text = lib.mkForce extraCssLight;
          force = true;
        };
        "gtk-4.0/gtk-dark.css" = {
          text = lib.mkForce extraCssDark;
          force = true;
        };

        "gtk-4.0/settings.ini".force = true;
        "gtk-3.0/gtk.css" = {
          text = lib.mkForce extraCssLight;
          force = true;
        };
        "gtk-3.0/gtk-dark.css" = {
          text = lib.mkForce extraCssDark;
          force = true;
        };
        "gtk-3.0/settings.ini".force = true;
      };
      gtk = {
        enable = cfg.enableTheme;
        font = {
          name = globals.fonts.sans;
          inherit (globals.fonts) size;
        };
        iconTheme = {
          name = if preferDark then
            "${globals.gtkIconTheme.name}-dark"
          else
            "${globals.gtkIconTheme.name}-light";
          inherit (globals.gtkIconTheme) package;
        };
        theme = {
          name = if preferDark then
            "${globals.gtkTheme.name}-dark"
          else
            globals.gtkTheme.name;
          inherit (globals.gtkTheme) package;
        };
        gtk3 = {
          extraCss = extraCssLight;
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
        gtk4.extraCss = extraCssLight;
      };
    };
  };
}
