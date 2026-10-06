#!/usr/bin/env bash
set -euo pipefail

# Front command for the article tools. It holds no logic of its own beyond
# chaining them: article-scrape, article-summarize, article-render and
# article-library each do one job and stay usable on their own.

model="${OMNIROUTE_MODEL:-desktop-free}"

usage() {
  cat >&2 <<'EOF'
usage: article [--force] [--render] [--debug] [--no-open] URL
       article render [--title TITLE] [--open] MARKDOWN
       article scrape [--debug] [--render] URL
       article summarize [--model MODEL] [ARTICLE_JSON]
       article index

  URL        scrape, summarize, render and save the summary in the library,
             then open it (reuses the saved summary unless --force)
  render     render MARKDOWN, save it under the library's rendered pages
             (not the summary list) and print its URL and file path
  scrape     print the article as JSON (article-scrape)
  summarize  print a Markdown summary of article JSON (article-summarize)
  index      rebuild the library's list pages and print the library URL

Summary options:
  --force    summarize again, without the input token limit
  --render   scrape with the headless browser right away
  --debug    print scraper and library details on stderr
  --no-open  print the summary URL instead of opening it
EOF
}

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/article.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

notify() {
  notify-send --app-name=article --app-icon="accessories-thesaurus" --hint=int:transient:1 "$1" "$2" || true
}

open_url() {
  local url=$1 opener_pid
  xdg-open "$url" >"$work_dir/xdg-open.log" 2>&1 &
  opener_pid=$!
  sleep 1
  if ! kill -0 "$opener_pid" 2>/dev/null && ! wait "$opener_pid"; then
    echo "article: could not open $url" >&2
    return 1
  fi
  disown "$opener_pid" 2>/dev/null || true
}

# --- article render ---------------------------------------------------------

render_markdown() {
  local title="" open=false markdown source location
  while (($#)); do
    case "$1" in
    --title)
      (($# >= 2)) || {
        usage
        exit 2
      }
      title=$2
      shift 2
      ;;
    --open)
      open=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage
      exit 2
      ;;
    *) break ;;
    esac
  done
  (($# == 1)) || {
    usage
    exit 2
  }
  markdown=$1
  [[ -f $markdown ]] || {
    echo "article: Markdown file does not exist: $markdown" >&2
    exit 1
  }
  source=$(realpath -- "$markdown")
  if [[ -z $title ]]; then
    title=$(sed -n 's/^# \(.*\)/\1/p;T;q' "$source")
    [[ -n $title ]] || title=$(basename -- "${source%.*}")
  fi

  article-render --title "$title" --copy "$source" --output "$work_dir/page.html" "$source" >/dev/null
  jq -n --arg title "$title" --arg source "$source" '{title: $title, source: $source}' >"$work_dir/page.json"
  location=$(article-library add --collection pages --key "$source" --meta "$work_dir/page.json" "$work_dir/page.html")
  jq -r '"url:  \(.url)\npath: \(.path)"' <<<"$location"
  if [[ $open == true ]]; then open_url "$(jq -r .url <<<"$location")"; fi
}

# --- article URL ------------------------------------------------------------

summarize_url() {
  local force=false debug=false browser=false open=true article_url canonical_url title location
  while (($#)); do
    case "$1" in
    --force) force=true ;;
    --debug) debug=true ;;
    --render) browser=true ;;
    --no-open) open=false ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage
      exit 2
      ;;
    *) break ;;
    esac
    shift
  done
  (($# == 1)) || {
    usage
    exit 2
  }
  article_url=$1

  # Shows a failure page from the library (errors are never listed) and exits.
  fail() {
    local stage=$1 message=$2 suggestion=${3:-"Retry the article or open the original link."} link_url="#"
    if [[ $article_url =~ ^https?://[^/?#[:space:]]+ ]]; then link_url=$article_url; fi
    jq -nr --arg stage "$stage" --arg message "$message" --arg suggestion "$suggestion" \
      --arg url "$article_url" --arg link "$link_url" --arg timestamp "$(date --iso-8601=seconds)" '
        [$stage,$message,$suggestion,$url,$link,$timestamp] | map(@html) |
        "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><title>Summary error</title><style>html{color-scheme:light dark;font:18px/1.6 system-ui}body{max-width:46rem;margin:auto;padding:2rem}code{overflow-wrap:anywhere}.error{border-left:.3rem solid #e64553;padding-left:1rem}</style></head><body><h1>Article summary failed</h1><div class=\"error\"><p><strong>Stage:</strong> \(.[0])</p><p>\(.[1])</p></div><p><strong>Suggested action:</strong> \(.[2])</p><p><strong>Article:</strong> <a href=\"\(.[4])\">\(.[3])</a></p><p><small>\(.[5])</small></p></body></html>"' >"$work_dir/error.html"
    jq -n --arg url "$article_url" --arg stage "$stage" '{title: "Summary failed", url: $url, stage: $stage}' >"$work_dir/error.json"
    notify "Article summary failed" "$stage: $message"
    echo "article: $stage: $message" >&2
    if location=$(article-library add --collection errors --key "$article_url" --meta "$work_dir/error.json" "$work_dir/error.html"); then
      [[ $open == true ]] && open_url "$(jq -r .url <<<"$location")"
    fi
    exit 1
  }

  # Reuses a saved summary; succeeds only when one exists for $1.
  show_saved() {
    [[ $force == false && $browser == false ]] || return 1
    location=$(article-library lookup --collection summaries --key "$1") || return 1
    finish "Opening saved summary"
  }

  finish() {
    notify "Article summary" "$1"
    if [[ $open == true ]]; then
      open_url "$(jq -r .url <<<"$location")" || fail "browser launch" "xdg-open could not be launched." "Check your XDG default browser configuration."
    else
      jq -r .url <<<"$location"
    fi
  }

  if [[ ! $article_url =~ ^https?://[^/?#[:space:]]+[^[:space:]]*$ ]]; then
    fail validation "The command requires one plausible HTTP or HTTPS URL." "Provide a normal web article URL."
  fi
  show_saved "$article_url" && return

  local scrape_args=()
  [[ $debug == true ]] && scrape_args+=(--debug)
  [[ $browser == true ]] && scrape_args+=(--render)
  if ! article-scrape "${scrape_args[@]}" "$article_url" >"$work_dir/article.json" 2>"$work_dir/scrape.error"; then
    fail scraping "$(head -c 500 "$work_dir/scrape.error")" \
      "The page may be unavailable, require login or interaction, or may not contain a full article."
  fi
  canonical_url=$(jq -r '.canonical_url' "$work_dir/article.json")
  [[ $canonical_url =~ ^https?://[^[:space:]]+$ ]] || canonical_url=$article_url
  show_saved "$canonical_url" && return

  title=$(jq -r '(.title // "Untitled article")[0:160]' "$work_dir/article.json")
  notify "Article summary started" "$title"

  local summarize_args=(--model "$model")
  [[ $force == true ]] && summarize_args+=(--max-input-tokens 0)
  if ! article-summarize "${summarize_args[@]}" "$work_dir/article.json" >"$work_dir/summary.md" 2>"$work_dir/summary.error"; then
    fail summary "$(head -c 500 "$work_dir/summary.error")" "Check OmniRoute, its endpoint key, and the '$model' combo."
  fi

  python3 "$COMPOSE_SUMMARY" "$work_dir/article.json" "$work_dir/summary.md" "$model" "$work_dir/page.md"
  if ! article-render --title "Article summary" --copy "$work_dir/summary.md" --output "$work_dir/page.html" \
    "$work_dir/page.md" >/dev/null 2>"$work_dir/render.error"; then
    fail rendering "$(head -c 500 "$work_dir/render.error")" "Check the extracted metadata and retry."
  fi
  if ! location=$(article-library add --collection summaries --key "$canonical_url" \
    --meta "$work_dir/page.json" "$work_dir/page.html" 2>"$work_dir/library.error"); then
    fail saving "$(head -c 500 "$work_dir/library.error")" "Check the article library folder."
  fi
  [[ $debug == true ]] && echo "article: saved $(jq -r .path <<<"$location")" >&2
  finish "Finished: $title"
}

case "${1:-}" in
scrape)
  shift
  exec article-scrape "$@"
  ;;
summarize)
  shift
  exec article-summarize "$@"
  ;;
index)
  shift
  exec article-library index "$@"
  ;;
render)
  shift
  render_markdown "$@"
  ;;
"" | -h | --help | help)
  usage
  [[ -n ${1:-} ]]
  ;;
*) summarize_url "$@" ;;
esac
