# Article Scrape

`article-scrape` fetches a web page and extracts its article content as JSON
(title, metadata, and Markdown body). It first tries a static HTTP fetch and
falls back to full browser rendering when the page needs JavaScript.

## Stack

| Component | Role |
|-----------|------|
| curl | Static page fetch |
| Python 3 + [Trafilatura](https://trafilatura.readthedocs.io/) | Article and metadata extraction (`extract.py`) |
| Python 3 + [Playwright](https://playwright.dev/python/) | Headless rendering fallback (`fetch_rendered.py`) |
| Google Chrome | Default browser executable for rendering |

## Setup

To use a different browser for the rendering
fallback, set `ARTICLE_SCRAPE_BROWSER` to an absolute executable path:

```sh
export ARTICLE_SCRAPE_BROWSER=$(which google-chrome-stable)
```

## Usage

```sh
article-scrape https://example.com/post
article-scrape --render https://spa-site.example.com/page   # skip static fetch, render directly
article-scrape --debug --render https://example.com/post    # print the browser used
```

Output is a single JSON document on stdout:

```json
{
  "url": "https://example.com/post",
  "title": "...",
  "author": "...",
  "date": "...",
  "content": "Markdown article body..."
}
```

Pipe the body into other tools with `jq`:

```sh
article-scrape https://example.com/post | jq --raw-output .content
```

Exit codes: `2` for a bad URL or arguments, `1` when fetching or extraction
fails (errors from both the static and rendered attempts are combined on
stderr).
