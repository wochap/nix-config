{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.yazi;
  inherit (config._custom.globals) themeColorsLight themeColorsDark;

  catppuccin-yazi-light-theme-path = "${inputs.catppuccin-yazi}/themes/${themeColorsLight.flavour}/catppuccin-${themeColorsLight.flavour}-blue.toml";
  catppuccin-yazi-dark-theme-path = "${inputs.catppuccin-yazi}/themes/${themeColorsDark.flavour}/catppuccin-${themeColorsDark.flavour}-blue.toml";
in
{
  options._custom.programs.yazi.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      programs.yazi = {
        enable = true;
        package = pkgs.nixpkgs-unstable.yazi;
        enableZshIntegration = config._custom.programs.zsh.enable;
        shellWrapperName = "f";
      };

      xdg.configFile = {
        "yazi/theme.toml".text = ''
          [flavor]
          dark  = "catppuccin-dark"
          light = "catppuccin-light"
        '';
        "yazi/flavors/catppuccin-light.yazi/flavor.toml".source = catppuccin-yazi-light-theme-path;
        "yazi/flavors/catppuccin-light.yazi/tmtheme.xml".text = "";
        "yazi/flavors/catppuccin-dark.yazi/flavor.toml".source = catppuccin-yazi-dark-theme-path;
        "yazi/flavors/catppuccin-dark.yazi/tmtheme.xml".text = "";
      };
    };
  };
}
