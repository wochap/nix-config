{ config, pkgs, lib, ... }:

{

  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options = {
    _custom.globals = {
      fonts = {
        sans = lib.mkOption {
          type = lib.types.str;
          default = "Source Sans Pro";
        };
        size = lib.mkOption {
          type = lib.types.int;
          default = 10;
        };
      };

      cursor = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Catppuccin-Mocha-Dark-Cursors";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.catppuccin-cursors.mochaDark;
        };
        size = lib.mkOption {
          type = lib.types.int;
          # 16, 32, 48 or 64
          default = 24;
        };
      };

      gtkTheme = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Catppuccin-Mocha-Standard-Mauve-Dark";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.catppuccin-gtk.override {
            accents = [ "mauve" ];
            size = "standard";
            tweaks = [ ];
            variant = "mocha";
          };
        };
      };
      gtkIconTheme = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Tela-catppuccin_mocha";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs._custom.tela-icon-theme.override {
            colorVariants = [ "catppuccin_mocha" "dracula" ];
          };
        };
      };

      displayServer = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "xorg"; # xorg, wayland, darwin
        description = "Display server type, used by common config files.";
      };
      isHidpi = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Flag for hidpi displays.";
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
        default = { };
        example = "{}";
        description = "Theme colors";
      };
    };

    _displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland, darwin
      description = "Display server type, used by common config files.";
    };
    _userName = lib.mkOption {
      type = lib.types.str;
      default = "gean";
      example = "gean";
      description = "Default user name";
    };
    _homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/gean";
      example = "/home/gean";
      description = "Path of user home folder";
    };
    _configDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/gean/nix-config";
      example = "/home/gean/nix-config";
      description = "Path of config folder";
    };
  };

  config = {
    environment.etc."scripts/theme-colors.sh" = {
      text = ''
        ${lib.concatStringsSep "\n"
        (lib.attrsets.mapAttrsToList (key: value: ''${key}="${value}"'')
          config._custom.globals.themeColors)}
      '';
      mode = "0755";
    };
  };
}
