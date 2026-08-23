{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  articlePython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.playwright
    pythonPackages.trafilatura
  ]);
  article-scrape = pkgs.writeShellApplication {
    name = "article-scrape";
    runtimeInputs = with pkgs; [
      articlePython
    ];
    runtimeEnv = {
      EXTRACTOR = ./extract.py;
      PAGE_RENDERER = ./fetch_rendered.py;
      ARTICLE_SCRAPE_BROWSER_DEFAULT = lib.getExe pkgs.prevstable-chrome.google-chrome;
    };
    text = builtins.readFile ./article-scrape.sh;
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.enableArticleSummary) {
    environment.systemPackages = [ article-scrape ];
  };
}
