# Article Summary

`article-page` is the reusable rendering layer. It turns any Markdown file into
a standalone HTML5 page and can optionally open it:

```sh
article-page --open notes.md
cat notes.md | article-page --output notes.html -
article-page --title "Weekly digest" --header header.html \
  --footer footer.html --output digest.html digest.md
```

Use `--head` for additions to the document `<head>`, or
`--no-default-style` when supplying all styling yourself. Enable it on its own
with `_custom.services.ai.enableArticlePage = true`; enabling article summaries
also installs it.

Enable the system-wide `article-summary` command with:

```nix
_custom.services.ai = {
  enable = true;
  enableOmniRoute = true;
  enableArticleSummary = true;
};
```

The command accepts an HTTP or HTTPS article URL, summarizes it through
OmniRoute, renders the result as HTML, and opens it with the configured XDG
browser. It can be invoked directly or integrated with an RSS reader.
