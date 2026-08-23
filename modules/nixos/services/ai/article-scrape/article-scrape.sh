#!/usr/bin/env bash
set -euo pipefail

debug=false
render=false

usage() { echo "usage: article-scrape [--debug] [--render] URL" >&2; }

while (($#)); do
  case "$1" in
  --debug) debug=true ;;
  --render) render=true ;;
  --help | -h)
    usage
    exit 0
    ;;
  --*)
    usage
    exit 2
    ;;
  *) break ;;
  esac
  shift
done

if (($# != 1)); then
  usage
  exit 2
fi
article_url=$1

if [[ ! $article_url =~ ^https?://[^/?#[:space:]]+[^[:space:]]*$ ]]; then
  echo "article-scrape: URL must use HTTP or HTTPS" >&2
  exit 2
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/article-scrape.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

effective_url=$article_url
static_error=""
if [[ $render == false ]]; then
  if ! effective_url=$(curl --fail --silent --show-error --location --max-redirs 5 \
    --connect-timeout 15 --max-time 45 --user-agent "article-scrape/1.0 (local article extractor)" \
    --output "$work_dir/article.html" --write-out '%{url_effective}' "$article_url"); then
    echo "article-scrape: could not fetch page" >&2
    exit 1
  fi

  if ! python3 "$EXTRACTOR" "$effective_url" "$work_dir/article.html" \
    >"$work_dir/article.json" 2>"$work_dir/extract.error"; then
    static_error=$(head -c 240 "$work_dir/extract.error")
    render=true
  fi
fi

if [[ $render == true ]]; then
  browser=${ARTICLE_SCRAPE_BROWSER:-$ARTICLE_SCRAPE_BROWSER_DEFAULT}
  [[ $debug == true ]] && echo "article-scrape: rendering with $browser" >&2
  if ! effective_url=$(python3 "$PAGE_RENDERER" "$effective_url" \
    "$work_dir/article.html" 2>"$work_dir/browser.error"); then
    browser_error=$(head -c 240 "$work_dir/browser.error")
    if [[ -n $static_error ]]; then
      browser_error="Static extraction: $static_error Browser rendering: $browser_error"
    fi
    echo "article-scrape: $browser_error" >&2
    exit 1
  fi
  if ! python3 "$EXTRACTOR" "$effective_url" "$work_dir/article.html" \
    >"$work_dir/article.json" 2>"$work_dir/extract.error"; then
    rendered_error=$(head -c 240 "$work_dir/extract.error")
    if [[ -n $static_error ]]; then
      rendered_error="Static extraction: $static_error Rendered extraction: $rendered_error"
    fi
    echo "article-scrape: $rendered_error" >&2
    exit 1
  fi
fi

cat "$work_dir/article.json"
