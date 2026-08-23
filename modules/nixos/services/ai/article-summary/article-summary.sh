#!/usr/bin/env bash
set -euo pipefail

model="${OMNIROUTE_MODEL:-desktop-free}"
cache_version="4"
force=false
debug=false
render=false
forced_render=false

usage() { echo "usage: article-summary [--force] [--debug] [--render] URL" >&2; }
while (($#)); do
  case "$1" in
  --force) force=true ;;
  --debug) debug=true ;;
  --render)
    render=true
    forced_render=true
    ;;
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

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/article-summaries"
mkdir -p "$cache_root"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/article-summary.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

notify() {
  local title=$1 message=$2
  notify-send --app-name=article-summary --app-icon="accessories-thesaurus" --hint=int:transient:1 "$title" "$message" || true
}

open_page() {
  local page=$1
  xdg-open "$page" >"$work_dir/xdg-open.log" 2>&1 &
  local opener_pid=$!
  sleep 1
  if ! kill -0 "$opener_pid" 2>/dev/null; then
    if ! wait "$opener_pid"; then
      echo "article-summary: could not launch xdg-open" >&2
      return 1
    fi
  fi
  disown "$opener_pid" 2>/dev/null || true
}

diagnose() {
  local stage=$1 message=$2 suggestion=${3:-"Retry the article or open the original link."}
  local diagnostic link_url="#"
  if [[ $article_url =~ ^https?://[^/?#[:space:]]+ ]]; then link_url=$article_url; fi
  diagnostic="$cache_root/diagnostic-$(printf '%s' "$article_url" | sha256sum | cut -d' ' -f1).html"
  jq -nr --arg stage "$stage" --arg message "$message" --arg suggestion "$suggestion" \
    --arg url "$article_url" --arg link "$link_url" --arg timestamp "$(date --iso-8601=seconds)" '
      [$stage,$message,$suggestion,$url,$link,$timestamp] | map(@html) |
      "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><title>Summary error</title><style>html{color-scheme:light dark;font:18px/1.6 system-ui}body{max-width:46rem;margin:auto;padding:2rem}code{overflow-wrap:anywhere}.error{border-left:.3rem solid #e64553;padding-left:1rem}</style></head><body><h1>Article summary failed</h1><div class=\"error\"><p><strong>Stage:</strong> \(.[0])</p><p>\(.[1])</p></div><p><strong>Suggested action:</strong> \(.[2])</p><p><strong>Article:</strong> <a href=\"\(.[4])\">\(.[3])</a></p><p><small>\(.[5])</small></p></body></html>"' >"$work_dir/diagnostic.html"
  mv "$work_dir/diagnostic.html" "$diagnostic"
  notify "Article summary failed" "$stage: $message"
  open_page "$diagnostic" || true
  echo "article-summary: $stage: $message" >&2
  exit 1
}

if [[ ! $article_url =~ ^https?://[^/?#[:space:]]+[^[:space:]]*$ ]]; then
  diagnose validation "The command requires one plausible HTTP or HTTPS URL." "Provide a normal web article URL."
fi

# Fast path for the common case. Redirect aliases intentionally are not guessed.
input_key=$(printf '%s\n%s' "$cache_version" "$article_url" | sha256sum | cut -d' ' -f1)
input_cache="$cache_root/$input_key.html"
if [[ $force == false && $forced_render == false && -s $input_cache ]]; then
  notify "Article summary" "Opening cached summary"
  open_page "$input_cache"
  exit 0
fi

effective_url=$article_url
static_error=""
if [[ $render == false ]]; then
  curl_error="$work_dir/curl.error"
  if ! effective_url=$(curl --fail --silent --show-error --location --max-redirs 5 \
    --connect-timeout 15 --max-time 45 --user-agent "article-summary/1.0 (local article summarizer)" \
    --output "$work_dir/article.html" --write-out '%{url_effective}' "$article_url" 2>"$curl_error"); then
    diagnose fetch "$(head -c 500 "$curl_error")" "Check the network and open the original article to confirm it is available."
  fi

  if ! python3 "$EXTRACTOR" "$effective_url" "$work_dir/article.html" >"$work_dir/article.json" 2>"$work_dir/extract.error"; then
    static_error=$(head -c 240 "$work_dir/extract.error")
    render=true
  fi
fi

if [[ $render == true ]]; then
  browser=${ARTICLE_SUMMARY_BROWSER:-$ARTICLE_SUMMARY_BROWSER_DEFAULT}
  [[ $debug == true ]] && echo "article-summary: rendering with $browser" >&2
  if ! effective_url=$(python3 "$PAGE_RENDERER" "$effective_url" "$work_dir/article.html" 2>"$work_dir/browser.error"); then
    browser_error=$(head -c 240 "$work_dir/browser.error")
    if [[ -n $static_error ]]; then
      browser_error="Static extraction: $static_error Browser rendering: $browser_error"
    fi
    diagnose rendering "$browser_error" "The page may require login or unsupported interaction; open the original article to confirm it is public."
  fi
  if ! python3 "$EXTRACTOR" "$effective_url" "$work_dir/article.html" >"$work_dir/article.json" 2>"$work_dir/extract.error"; then
    rendered_error=$(head -c 240 "$work_dir/extract.error")
    if [[ -n $static_error ]]; then
      rendered_error="Static extraction: $static_error Rendered extraction: $rendered_error"
    fi
    diagnose extraction "$rendered_error" "The rendered page may require login or interaction, or may not contain a full article."
  fi
fi
rm -f "$work_dir/article.html"

canonical_url=$(jq -r '.canonical_url' "$work_dir/article.json")
if [[ ! $canonical_url =~ ^https?://[^[:space:]]+$ ]]; then canonical_url=$effective_url; fi
cache_key=$(printf '%s\n%s' "$cache_version" "$canonical_url" | sha256sum | cut -d' ' -f1)
cached_html="$cache_root/$cache_key.html"
if [[ $force == false && $forced_render == false && -s $cached_html ]]; then
  notify "Article summary" "Opening cached summary"
  open_page "$cached_html"
  exit 0
fi

article_title=$(jq -r '(.title // "Untitled article")[0:160]' "$work_dir/article.json")
notify "Article summary started" "$article_title"

jq -r '.body' "$work_dir/article.json" >"$work_dir/article.md"
summary_args=(--format raw --model "$model" --title "$article_title")
if [[ $force == true ]]; then summary_args+=(--max-input-tokens 0); fi
if ! summary=$(summary "${summary_args[@]}" "$work_dir/article.md" 2>"$work_dir/summary.error"); then
  diagnose summary "$(head -c 500 "$work_dir/summary.error")" "Check OmniRoute, its endpoint key, and the '$model' combo."
fi

# Python JSON decoding safely transports metadata; Pandoc's raw_html extension is disabled below.
python3 "$RENDERER" "$work_dir/article.json" "$work_dir/summary.md" "$model" "$canonical_url" "$summary"
if ! article-page --title "Article summary" --output "$work_dir/summary.html" \
  "$work_dir/summary.md" >/dev/null 2>"$work_dir/pandoc.error"; then
  diagnose Pandoc "$(head -c 500 "$work_dir/pandoc.error")" "Check the extracted metadata and retry."
fi
printf '%s' "$summary" >"$work_dir/copy.md"
if ! python3 "$INJECTOR" "$work_dir/summary.html" "$work_dir/copy.md"; then
  diagnose rendering "Could not add the Markdown copy controls." "Check the summary renderer and retry."
fi
mv "$work_dir/summary.html" "$cached_html"
[[ $debug == true ]] && echo "article-summary: cached $cached_html" >&2
open_page "$cached_html" || diagnose "browser launch" "xdg-open could not be launched." "Check your XDG default browser configuration."
notify "Article summary finished" "$article_title"
