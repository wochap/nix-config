# Article Page

`article-page` is the reusable rendering layer. It turns any Markdown file
into a standalone HTML5 page with a built-in default stylesheet, and can
optionally open the result in a browser.

## Usage

```sh
article-page --open notes.md
cat notes.md | article-page --output notes.html -
article-page --title "Weekly digest" --header header.html \
  --footer footer.html --output digest.html digest.md
```

Use `--head` for additions to the document `<head>`, or `--no-default-style`
when supplying all styling yourself.
