{
  lib,
  writeShellApplication,
  python3,
  curl,
  prevstable-chrome,
}:

let
  scrapePython = python3.withPackages (pythonPackages: [
    pythonPackages.playwright
    pythonPackages.trafilatura
  ]);
in
writeShellApplication {
  name = "article-scrape";
  runtimeInputs = [
    scrapePython
    curl
  ];
  runtimeEnv = {
    EXTRACTOR = ./extract.py;
    PAGE_RENDERER = ./fetch_rendered.py;
    ARTICLE_SCRAPE_BROWSER_DEFAULT = lib.getExe prevstable-chrome.google-chrome;
  };
  text = builtins.readFile ./article-scrape.sh;
  meta.description = "Fetch a web page and print its article as JSON";
}
