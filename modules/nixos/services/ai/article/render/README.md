# Article Render

`article-render` turns any Markdown file into a standalone HTML5 page with a
built-in stylesheet (`article-render.css`), and can optionally open the
result in a browser. It knows nothing about articles, summaries or the
library; callers build the Markdown and decide where the page goes. Raw HTML
in the Markdown is disabled.

## Usage

```sh
article-render --open notes.md
cat notes.md | article-render --output notes.html -
article-render --title "Weekly digest" --header header.html \
  --footer footer.html --output digest.html digest.md
article-render --copy summary.md page.md   # adds a "Copy Markdown" button (key: y)
```

Use `--head` for additions to the document `<head>`, or `--no-default-style`
when supplying all styling yourself. `--copy FILE` embeds FILE and places the
button after an `a.original` link, or at the top of the page
(`copy_controls.py`). The path of the written page is printed on stdout.

To save a rendered page in the library instead, use `article render FILE.md`.
