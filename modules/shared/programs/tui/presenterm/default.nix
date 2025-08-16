{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.presenterm;
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;

  mkThemePresenterm = themeColors: ''
    defaults:
      theme: catppuccin-${themeColors.flavour}
    ${lib.fileContents ./dotfiles/config.yaml}
  '';
  catppuccin-presenterm-light-theme = mkThemePresenterm themeColorsLight;
  catppuccin-presenterm-dark-theme = mkThemePresenterm themeColorsDark;
in {
  options._custom.programs.presenterm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: didn't work in p zsh fn
    # _custom.programs.rod = {
    #   aliases = [ "presenterm" ];
    #   config = {
    #     cmds.presenterm.light.pre_args =
    #       [ "--theme=catppuccin-${themeColorsLight.flavour}" ];
    #     cmds.presenterm.dark.pre_args =
    #       [ "--theme=catppuccin-${themeColorsDark.flavour}" ];
    #   };
    # };

    _custom.hm = {
      home.packages = with pkgs; [ presenterm ];

      xdg.configFile = {
        "presenterm/config.yaml" = {
          text = if preferDark then
            catppuccin-presenterm-dark-theme
          else
            catppuccin-presenterm-light-theme;
          force = true;
        };
        "presenterm/config-light.yaml".text = catppuccin-presenterm-light-theme;
        "presenterm/config-dark.yaml".text = catppuccin-presenterm-dark-theme;
      };
      programs.zsh.initContent =
        lib.mkOrder 1000 (builtins.readFile ./dotfiles/p.zsh);
    };
  };
}
