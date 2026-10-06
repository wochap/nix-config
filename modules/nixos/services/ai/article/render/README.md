# article render

Renders any Markdown file as a standalone HTML5 page with the built-in
stylesheet (`article-render.css`). Raw HTML in the Markdown is disabled.

```sh
article render notes.md                    # save in the library under /pages/, print URL and path
article render --open --title "Notes" notes.md
article render -o notes.html notes.md      # only write the page; nothing is saved
```

The title defaults to the file's first `# heading`, else its name. Every
page gets a "Copy Markdown" button (key: `y`) with the source Markdown.
Rendering the same file again replaces its library page.

## Internal tool

`article-render` (`article-render.sh`) is the renderer behind this and
behind the library's list pages. It knows nothing about articles or the
library. Besides `--title`, `--output` and `--open` it takes `--head`,
`--header` and `--footer` files, `--no-default-style`, and `--copy FILE`,
which embeds FILE and places the copy button after an `a.original` link or
at the top of the page (`copy_controls.py`).
