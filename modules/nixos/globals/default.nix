{ pkgs, lib, ... }:

{
  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options._custom.globals = {
    cursor = {
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

    # file manager icons
    iconTheme = {
      name = lib.mkOption {
        type = lib.types.str;
        # NOTE: never add suffix `-dark`/`-light`
        default = "Tela-catppuccin_mocha_lavender";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs._custom.tela-icon-theme.override {
          colorVariants = [ "catppuccin_mocha_lavender" ];
        };
      };
    };

    displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland
      description = "Display server type, used by common config files.";
    };
  };
}
