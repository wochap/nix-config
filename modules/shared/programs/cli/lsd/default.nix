{ config, lib, inputs, ... }:

let
  cfg = config._custom.programs.lsd;
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;
in {
  options._custom.programs.lsd.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      xdg.configFile = {
        "lsd/light.yaml".source =
          "${inputs.catppuccin-lsd}/themes/catppuccin-${themeColorsLight.flavour}/colors.yaml";
        "lsd/dark.yaml".source =
          "${inputs.catppuccin-lsd}/themes/catppuccin-${themeColorsDark.flavour}/colors.yaml";
        "lsd/colors.yaml" = {
          source = "${inputs.catppuccin-lsd}/themes/catppuccin-${
              if preferDark then
                themeColorsDark.flavour
              else
                themeColorsLight.flavour
            }/colors.yaml";
          force = true;
        };
        "lsd/icons.yaml".text = ''
          name:
            mail: 
            Mail: 
        '';
      };

      programs.lsd = {
        enable = true;
        # adds ls ll la lt ll
        enableBashIntegration = true;
        enableZshIntegration = config._custom.programs.zsh.enable;
        settings = {
          color.theme = "custom";
          sorting.dir-grouping = "first";
          symlink-arrow = "->";
          layout = "grid";
          hyperlink = "auto";
          blocks = [ "permission" "user" "group" "size" "date" "git" "name" ];
          date = "+%a %d %b %H:%M %Y";
        };
      };
    };
  };
}
