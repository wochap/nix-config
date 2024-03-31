{ config, lib, ... }:

let
  catppuccinMochaTheme = import ./catppuccin-mocha.nix;
  inherit (config._custom.globals) themeColors;
in {
  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options._custom.globals = {
    fonts = {
      sans = lib.mkOption {
        type = lib.types.str;
        default = "Source Sans Pro";
      };
      # TODO: add monospace and serif
      size = lib.mkOption {
        type = lib.types.int;
        default = 10;
      };
    };

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

    themeColors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = catppuccinMochaTheme;
      example = "{}";
      description = "Theme colors";
    };
  };

  config = {
    _custom.hm = {
      xdg.configFile = {
        "scripts/theme-colors.sh" = {
          text = ''
            ${lib.concatStringsSep "\n"
            (lib.attrsets.mapAttrsToList (key: value: ''${key}="${value}"'')
              config._custom.globals.themeColors)}
          '';
          executable = true;
        };

        "theme-colors.css".text = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "@define-color ${key} ${value};") themeColors)}
        '';
      };
    };
  };
}
