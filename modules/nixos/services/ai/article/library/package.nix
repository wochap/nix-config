{
  writeShellApplication,
  python3,
  article-render,
  url ? "",
}:

writeShellApplication {
  name = "article-library";
  runtimeInputs = [
    python3
    article-render
  ];
  # Pages are printed with this base URL (the library server) instead of file:// paths.
  runtimeEnv.ARTICLE_LIBRARY_URL = url;
  text = ''
    exec python3 ${./article-library.py} "$@"
  '';
  meta.description = "Store rendered article pages and keep their list pages up to date";
}
