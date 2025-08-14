{ pkgs, lib, ... }:

{
  options._custom.globals = {
    # file manager icons
    iconTheme = {
      name = lib.mkOption {
        type = lib.types.str;
        # NOTE: never add suffix `-dark`/`-light`
        default = "Tela-catppuccin_mocha_blue";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs._custom.tela-icon-theme.override {
          colorVariants = [
            "catppuccin_mocha_sky"
            "catppuccin_mocha_blue"
            "catppuccin_mocha_lavender"
          ];
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
