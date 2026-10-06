# Article

Tools to scrape web articles, summarize them through OmniRoute, render
Markdown as styled HTML pages, and keep those pages in a library served at
`https://articles.wochap.local`.

```sh
article https://example.com/long-post        # scrape → summarize → render → save → open
article render notes.md                       # render and save; prints URL and path
article scrape https://example.com/post | jq .title
article index                                 # rebuild the list pages
```

## Architecture

Four single-purpose tools and one front command. Each tool reads files or
stdin, writes stdout, and exits non-zero with a message on stderr. Only the
library keeps state.

| Tool | Input → output | State |
|------|----------------|-------|
| [`article-scrape`](scrape/README.md) | URL → article JSON | none |
| [`article-summarize`](summarize/README.md) | article JSON → summary Markdown | none |
| [`article-render`](render/README.md) | Markdown → standalone HTML page | none |
| [`article-library`](library/README.md) | HTML page + metadata → stored page, list pages | owns the library folder |
| `article` (`article.sh`) | front command chaining the tools | none |

```
article URL:
  article-scrape ─► article-summarize ─► compose_summary.py ─► article-render ─► article-library add summaries ─► xdg-open
       │                                   (summary page template)                   │
       └──── article-library lookup (saved summary? open it, stop) ◄────────────────┘ same key: canonical URL

article render FILE.md:
  article-render ─► article-library add pages ─► print URL and path
```

Rules that keep it maintainable:

- **One job per tool.** A tool never calls a sibling except through its
  documented contract. `article-library` uses `article-render` for its list
  pages; nothing else crosses over.
- **`article` holds no logic.** It parses flags, chains tools, and turns
  failures into a notification and an error page. Summary page layout lives
  in `compose_summary.py`; storage lives in `article-library`.
- **The library is the only stateful part.** No other tool knows the
  library folder, its URL, or how ids are made; they get a location back as
  JSON from `article-library add|lookup`.
- **Packages are plain functions.** Each `package.nix` is a `callPackage`
  function whose dependencies are explicit `runtimeInputs`. `default.nix` is
  the only NixOS module: it builds the packages, installs them, and runs the
  library server. `summary` and `omniroute-chat` come from the ai and
  omniroute modules.

## Layout

```
article/
  default.nix           NixOS module: packages, library server, proxy
  package.nix           `article` front command
  article.sh
  compose_summary.py    summary page Markdown and its library metadata
  scrape/               article-scrape
  summarize/            article-summarize
  render/               article-render (+ default stylesheet, copy button)
  library/              article-library
```

To add a tool: create `<tool>/package.nix` and its script, build it in
`default.nix` with `pkgs.callPackage`, add it to `environment.systemPackages`
and, when `article` needs it, to `package.nix`'s inputs and a subcommand in
`article.sh`.

## Library and server

Pages live in `~/.local/share/article-library` (`$XDG_DATA_HOME`):
summaries at `/`, rendered pages at `/pages/`, failure pages unlisted under
`/errors/`. Lists are rebuilt on every save and when the server starts. The
`article-library` user service serves the folder read-only with Python's
`http.server`, started on the first request through
`https://articles.wochap.local`.

## Configuration

- `_custom.services.ai.enableArticle` enables everything; requires
  `enableOmniRoute`.
- `OMNIROUTE_MODEL` picks the summary combo (default `desktop-free`);
  `OMNIROUTE_REASONING_EFFORT` defaults to `none` for summaries.
- `ARTICLE_SCRAPE_BROWSER` overrides the browser used for rendering pages.
- `ARTICLE_LIBRARY_DIR` overrides the library folder.

Newsboat binds `s` to `article %u` and `S` to `article --force %u`.
