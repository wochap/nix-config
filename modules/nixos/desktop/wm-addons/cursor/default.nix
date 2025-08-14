{ config, lib, pkgs, ... }:

let cfg = config._custom.desktop.cursor;
in {
  options._custom.desktop.cursor = {
    enable = lib.mkEnableOption { };
    # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
    # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
    # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
    name = lib.mkOption {
      type = lib.types.str;
      default = "catppuccin-mocha-dark-cursors";
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

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    _custom.hm = {
      home.pointerCursor = {
        inherit (cfg) name package size;
        x11.enable = true;
        gtk.enable = config._custom.desktop.gtk.enableTheme;
      };

      gtk.cursorTheme = lib.mkIf config._custom.desktop.gtk.enableTheme {
        inherit (cfg) package name size;
      };

      systemd.user.services.xsetroot = lib._custom.mkWaylandService {
        Service = {
          Type = "oneshot";
          ExecStart =
            "${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr";
        };
      };
    };
  };
}
