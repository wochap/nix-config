{
  writeShellApplication,
  writeText,
  pandoc,
  python3,
  xdg-utils,
}:

let
  defaultHead = writeText "article-render-head.html" ''
    <style>
    ${builtins.readFile ./article-render.css}
    </style>
  '';
in
writeShellApplication {
  name = "article-render";
  runtimeInputs = [
    pandoc
    python3
    xdg-utils
  ];
  runtimeEnv = {
    ARTICLE_RENDER_DEFAULT_HEAD = defaultHead;
    COPY_CONTROLS = ./copy_controls.py;
  };
  text = builtins.readFile ./article-render.sh;
  meta.description = "Render a Markdown file as a standalone HTML page";
}
