{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  chrome = pkgs.prevstable-chrome.google-chrome;
  articlePython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.playwright
    pythonPackages.trafilatura
  ]);
  summaryHeader = pkgs.writeText "article-summary-header.html" ''
    <style>
    ${builtins.readFile ./summary.css}
    </style>
  '';
  newsboat-summary = pkgs.writeShellApplication {
    name = "newsboat-summary";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gnugrep
      gnused
      jq
      libnotify
      pandoc
      xdg-utils
      articlePython
      chrome
    ];
    runtimeEnv = {
      EXTRACTOR = ./extract.py;
      PAGE_RENDERER = ./fetch_rendered.py;
      RENDERER = ./render.py;
      INJECTOR = ./inject_controls.py;
      HEADER = summaryHeader;
      NEWSBOAT_SUMMARY_BROWSER_DEFAULT = lib.getExe chrome;
    };
    text = builtins.readFile ./newsboat-summary.sh;
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.enableArticleSummary) {
    assertions = [
      {
        assertion = cfg.enableOmniRoute;
        message = "_custom.services.ai.enableArticleSummary requires enableOmniRoute.";
      }
    ];

    environment.systemPackages = [ newsboat-summary ];
  };
}
