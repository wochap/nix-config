{ config, lib, ... }:

let
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;

  catppuccinLatteTheme = import ./catppuccin-latte.nix;
  catppuccinMochaTheme = import ./catppuccin-mocha.nix;
  mkThemeScript = colors:
    lib.concatStringsSep "\n"
    (lib.attrsets.mapAttrsToList (key: value: ''${key}="${value}"'')
      (builtins.removeAttrs colors [ "flavour" ]));
  mkThemeGtk = colors:
    lib.concatStringsSep "\n"
    (lib.attrsets.mapAttrsToList (key: value: "@define-color ${key} ${value};")
      (builtins.removeAttrs colors [ "flavour" ]));
in {
  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options._custom.globals = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "gean";
      example = "gean";
      description = "Default user name";
    };
    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/gean";
      example = "/home/gean";
      description = "Path of user home folder";
    };
    configDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/gean/nix-config";
      example = "/home/gean/nix-config";
      description = "Path of config folder";
    };

    fonts = {
      sans = lib.mkOption {
        type = lib.types.str;
        default = "Source Sans Pro";
      };
      serif = lib.mkOption {
        type = lib.types.str;
        default = "Source Serif Pro";
      };
      monospace = lib.mkOption {
        type = lib.types.str;
        default = "Source Code Pro";
      };
      size = lib.mkOption {
        type = lib.types.int;
        default = 10;
      };
    };

    # TODO: add a OLED variant
    # this is highly opinionated to catppuccin theme
    preferDark = lib.mkEnableOption { default = true; };
    # TODO: remove themeColors or replace with prefered dark/light
    themeColors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = if preferDark then themeColorsDark else themeColorsLight;
      example = "{}";
      description = "Theme colors";
    };
    themeColorsLight = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = catppuccinLatteTheme;
      example = "{}";
      description = "Theme colors";
    };
    themeColorsDark = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = catppuccinMochaTheme;
      example = "{}";
      description = "Theme colors dark";
    };
  };

  config = {
    _custom.hm = {
      xdg.configFile = {
        "scripts/theme-colors.sh" = {
          text = ''
            CURRENT_SCHEME=$(color-scheme print)
            if [[ "$CURRENT_SCHEME" == "dark" ]]; then
              ${mkThemeScript themeColorsDark}
            else
              ${mkThemeScript themeColorsLight}
            fi
          '';
          executable = true;
        };
        # TODO: do we need these?
        "scripts/theme-colors-light.sh" = {
          text = mkThemeScript themeColorsLight;
          executable = true;
        };
        "scripts/theme-colors-dark.sh" = {
          text = mkThemeScript themeColorsDark;
          executable = true;
        };

        "theme-colors-gtk.css".text =
          mkThemeGtk (if preferDark then themeColorsDark else themeColorsLight);
        "theme-colors-gtk-light.css".text = mkThemeGtk themeColorsLight;
        "theme-colors-gtk-dark.css".text = mkThemeGtk themeColorsDark;
      };
    };
  };
}
