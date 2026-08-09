{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.newsboat;
  inherit (config._custom.globals)
    themeColorsLight
    themeColorsDark
    preferDark
    configDirectory
    ;

  articlePython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.trafilatura ]);
  summaryHeader = pkgs.writeText "newsboat-summary-header.html" ''
    <style>
    ${builtins.readFile ./summary/summary.css}
    </style>
  '';
  newsboat-summary = pkgs.writeShellApplication {
    name = "newsboat-summary";
    runtimeInputs = with pkgs; [
      pandoc
      articlePython
    ];
    runtimeEnv = {
      EXTRACTOR = ./summary/extract.py;
      RENDERER = ./summary/render.py;
      HEADER = summaryHeader;
    };
    text = builtins.readFile ./summary/newsboat-summary.sh;
  };
  mkThemeNewsboat =
    themeColors:
    "${inputs.catppuccin-newsboat}/themes/${
      if themeColors.flavour == "latte" then "latte" else "dark"
    }";
  catppuccin-newsboat-light-theme-path = mkThemeNewsboat themeColorsLight;
  catppuccin-newsboat-dark-theme-path = mkThemeNewsboat themeColorsDark;
in
{
  options._custom.programs.newsboat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        newsboat
        newsboat-summary
        urlscan # extract urls from emails/txt files
      ];

      xdg.configFile = {
        "newsboat/theme" = {
          source =
            if preferDark then catppuccin-newsboat-dark-theme-path else catppuccin-newsboat-light-theme-path;
          force = true;
        };
        "newsboat/theme-light".source = catppuccin-newsboat-light-theme-path;
        "newsboat/theme-dark".source = catppuccin-newsboat-dark-theme-path;
        "newsboat/urls".source = lib._custom.relativeSymlink configDirectory ./dotfiles/urls;
        "newsboat/config".source = lib._custom.relativeSymlink configDirectory ./dotfiles/config;
      };
    };
  };
}
