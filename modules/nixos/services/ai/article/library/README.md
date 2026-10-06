# Article Library

`article-library` stores rendered HTML pages and keeps their list pages up
to date. It is the only article tool with state; the others get a location
back from it.

```sh
article-library add --collection summaries --key https://example.com/post --meta page.json page.html
article-library lookup --collection summaries --key https://example.com/post
article-library index
```

`add` and `lookup` print `{"id", "collection", "path", "url"}`; `lookup`
exits `1` when the key is not stored. `--meta` is a JSON object; `title`,
`source` and `author` show in the list, other fields are kept as is. The id
is derived from the key, so adding the same key replaces the page.

| Collection | Folder | Listed at |
|------------|--------|-----------|
| `summaries` | `summaries/` | `index.html` (`/`) |
| `pages` | `pages/` | `pages/index.html` |
| `errors` | `errors/` | not listed |

Each page `<id>.html` has a `<id>.json` record. Lists group entries by the
day they were added, newest first, and are rendered with `article-render`.
The folder is `ARTICLE_LIBRARY_DIR`, default
`$XDG_DATA_HOME/article-library`; URLs use `ARTICLE_LIBRARY_URL`, set to the
library server by the package, or `file://` paths when empty.
