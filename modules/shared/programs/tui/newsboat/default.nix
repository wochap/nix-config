{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.newsboat;
  inherit (config._custom.globals)
    themeColorsLight themeColorsDark preferDark configDirectory;

  qndl = pkgs.writeShellScriptBin "qndl" (builtins.readFile ./scripts/qndl.sh);
  linkhandler = pkgs.writeShellScriptBin "linkhandler"
    (builtins.readFile ./scripts/linkhandler.sh);
  mkThemeNewsboat = themeColors:
    "${inputs.catppuccin-newsboat}/themes/${
      if themeColors.flavour == "latte" then "latte" else "dark"
    }";
  catppuccin-newsboat-light-theme-path = mkThemeNewsboat themeColorsLight;
  catppuccin-newsboat-dark-theme-path = mkThemeNewsboat themeColorsDark;
in {
  options._custom.programs.newsboat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        newsboat
        qndl
        linkhandler
        urlscan # extract urls from emails/txt files
      ];

      xdg.configFile = {
        "newsboat/theme" = {
          source = if preferDark then
            catppuccin-newsboat-dark-theme-path
          else
            catppuccin-newsboat-light-theme-path;
          force = true;
        };
        "newsboat/theme-light".source = catppuccin-newsboat-light-theme-path;
        "newsboat/theme-dark".source = catppuccin-newsboat-dark-theme-path;
        "newsboat/urls".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/urls;
        "newsboat/config".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/config;
      };
    };
  };
}
