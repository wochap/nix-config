#!/usr/bin/env bash
set -euo pipefail

open=false
output=""
title=""
default_style=true
head_files=()
header_files=()
footer_files=()

usage() {
  cat >&2 <<'EOF'
usage: article-page [OPTIONS] MARKDOWN

Render a Markdown file as a standalone HTML5 page. Use - to read from stdin.

  -o, --output FILE   write to FILE (default: MARKDOWN.html or article.html for stdin)
      --title TITLE   set the HTML document title
      --head FILE     append HTML to <head> (may be repeated)
      --header FILE   insert HTML before the rendered Markdown (may be repeated)
      --footer FILE   insert HTML after the rendered Markdown (may be repeated)
      --no-default-style
                       omit the built-in responsive stylesheet
      --open           open the resulting page with xdg-open
  -h, --help           show this help
EOF
}

while (($#)); do
  case "$1" in
  -o | --output)
    (($# >= 2)) || {
      usage
      exit 2
    }
    output=$2
    shift 2
    ;;
  --title | --head | --header | --footer)
    (($# >= 2)) || {
      usage
      exit 2
    }
    case "$1" in
    --title) title=$2 ;;
    --head) head_files+=("$2") ;;
    --header) header_files+=("$2") ;;
    --footer) footer_files+=("$2") ;;
    esac
    shift 2
    ;;
  --no-default-style)
    default_style=false
    shift
    ;;
  --open)
    open=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --*)
    usage
    exit 2
    ;;
  *) break ;;
  esac
done

if (($# != 1)); then
  usage
  exit 2
fi
markdown=$1
if [[ $markdown != - && ! -f $markdown ]]; then
  echo "article-page: Markdown file does not exist: $markdown" >&2
  exit 1
fi
if [[ -z $output ]]; then
  if [[ $markdown == - ]]; then
    output=article.html
  else
    output=${markdown%.*}.html
    [[ $output != "$markdown" ]] || output="$markdown.html"
  fi
fi

pandoc_args=(--from=markdown-raw_html --to=html5 --standalone --output="$output")
if [[ $default_style == true ]]; then
  pandoc_args+=(--include-in-header="$ARTICLE_PAGE_DEFAULT_HEAD")
fi
for file in "${head_files[@]}"; do pandoc_args+=(--include-in-header="$file"); done
for file in "${header_files[@]}"; do pandoc_args+=(--include-before-body="$file"); done
for file in "${footer_files[@]}"; do pandoc_args+=(--include-after-body="$file"); done
if [[ -n $title ]]; then pandoc_args+=(--metadata "title=$title"); fi

pandoc "${pandoc_args[@]}" "$markdown"
printf '%s\n' "$output"

if [[ $open == true ]]; then
  xdg-open "$output" >/dev/null 2>&1 &
  disown "$!" 2>/dev/null || true
fi
