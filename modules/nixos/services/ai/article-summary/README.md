# Article Summary

`article-summary` takes an HTTP/HTTPS article URL, scrapes it, summarizes the
content through OmniRoute, renders the summary as a standalone HTML page, and
opens it with the configured XDG browser. It can be invoked directly or
integrated with an RSS reader.

## Stack

| Component | Role |
|-----------|------|
| [article-scrape](../article-scrape/README.md) | URL → article JSON (static fetch with browser fallback) |
| OmniRoute (`omniroute-chat`) | LLM summarization (default combo `desktop-free`) |
| Pandoc + [article-page](../article-page/README.md) | Markdown summary → HTML page (`render.py`) |
| Python 3 | Metadata injection and controls (`inject_controls.py`) |

## Usage

```sh
article-summary https://example.com/long-post
```

The pipeline: `article-scrape` extracts the article, the summary model
condenses it, `article-page` renders the result, and the page opens in your
browser. Errors from scraping or summarization are reported on stderr with a
suggested fix.
