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
          default = "JetBrainsMono Nerd Font";
        };
      };

      cursor = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "capitaine-cursors";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.capitaine-cursors;
        };
        size = lib.mkOption {
          type = lib.types.int;
          # 16, 32, 48 or 64
          default = 24;
        };
      };

      theme = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Dracula";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.dracula-theme;
        };
      };

      displayServer = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "xorg"; # xorg, wayland, darwin
        description = "Display server type, used by common config files.";
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
      # theme = lib.mkOption {
      #   type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      #   default = { };
      #   example = "{}";
      #   description = "Theme colors";
      # };
    };

    _displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland, darwin
      description = "Display server type, used by common config files.";
    };
    _isHidpi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Flag for hidpi displays.";
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
    _theme = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
      example = "{}";
      description = "Theme colors";
    };
    _isNvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Flag for devices with nvidia.";
    };
  };

  config = {
    environment.etc."scripts/theme-colors.sh" = {
      text = ''
        ${lib.concatStringsSep "\n"
        (lib.attrsets.mapAttrsToList (key: value: ''${key}="${value}"'')
          config._theme)}
      '';
      mode = "0755";
    };
  };
}
