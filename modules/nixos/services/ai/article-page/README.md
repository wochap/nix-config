# Article Page

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
