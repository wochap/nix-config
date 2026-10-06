{
  writeShellApplication,
  jq,
  python3,
  xdg-utils,
  libnotify,
  article-scrape,
  article-summarize,
  article-render,
  article-library,
}:

writeShellApplication {
  name = "article";
  runtimeInputs = [
    jq
    python3
    xdg-utils
    libnotify
    article-scrape
    article-summarize
    article-render
    article-library
  ];
  runtimeEnv.COMPOSE_SUMMARY = ./compose_summary.py;
  text = builtins.readFile ./article.sh;
  meta.description = "Scrape, summarize, render and save web articles";
}
