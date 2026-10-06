# article summarize

Reads article JSON from `article scrape` (file or stdin) and prints a
Markdown summary of its body, through `summary` (article preset) and
OmniRoute.

```sh
article scrape https://example.com/post | article summarize
article summarize --model another-combo --max-input-tokens 0 article.json
```

`--model` defaults to `OMNIROUTE_MODEL` or `desktop-free`; the reasoning
effort defaults to `none` (`OMNIROUTE_REASONING_EFFORT`). Exit code `2` means
the input is not article JSON with a body; `1` means summarization failed.

The internal tool is `article-summarize` (`article-summarize.sh`).
