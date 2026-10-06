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
`--header` and `--footer` files, `--no-default-style`, `--metadata-file FILE`
(YAML/JSON parsed as Markdown, so a title can be a link), and `--copy FILE`,
which embeds FILE and places the copy button after an `a.original` link or
at the top of the page (`copy_controls.py`).

## Stylesheet

`article-render.css` is adapted from the Claude Design handoff in
`../design/project/summaries.css` (Catppuccin Latte/Mocha, light/dark).
Pages with a top-level `.nav` block get the list layout (day headings with a
`{count="N"}` badge, `.source`/`.author` spans, `.empty` state); every other
page gets the reading layout. A title that is a link renders as a small
"← back" breadcrumb. The faces (Source Serif 4, IBM Plex Sans, JetBrains
Mono) are installed by the module; there are no web fonts.

