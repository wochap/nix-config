{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  defaultHead = pkgs.writeText "article-page-head.html" ''
    <style>
    ${builtins.readFile ./article-page.css}
    </style>
  '';
  article-page = pkgs.writeShellApplication {
    name = "article-page";
    runtimeEnv.ARTICLE_PAGE_DEFAULT_HEAD = defaultHead;
    text = builtins.readFile ./article-page.sh;
    meta.description = "Render a Markdown file as a standalone HTML page";
  };
in
{
  config = lib.mkIf (cfg.enable && (cfg.enableArticlePage || cfg.enableArticleSummary)) {
    environment.systemPackages = [ article-page ];
  };
}
