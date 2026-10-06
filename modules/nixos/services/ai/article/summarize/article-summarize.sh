#!/usr/bin/env bash
set -euo pipefail

model="${OMNIROUTE_MODEL:-desktop-free}"
# Summaries need no reasoning; omniroute-chat (via summary) reads this.
export OMNIROUTE_REASONING_EFFORT="${OMNIROUTE_REASONING_EFFORT:-none}"
summary_args=()

usage() {
  cat >&2 <<'USAGE'
usage: article-summarize [--model MODEL] [--max-input-tokens TOKENS] [ARTICLE_JSON]

Summarize an article-scrape JSON document (file, or stdin when omitted or -)
and print the summary as Markdown. Uses `summary` with the article preset.

  --model MODEL              OmniRoute model or combo (default: OMNIROUTE_MODEL or desktop-free)
  --max-input-tokens TOKENS  input limit passed to summary; 0 for no limit
USAGE
}

while (($#)); do
  case "$1" in
  --model | --max-input-tokens)
    (($# >= 2)) || {
      usage
      exit 2
    }
    if [[ $1 == --model ]]; then model=$2; else summary_args+=(--max-input-tokens "$2"); fi
    shift 2
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
(($# <= 1)) || {
  usage
  exit 2
}
input=${1:--}

article=$(cat -- "$input")
if ! title=$(jq -er '(.title // "Untitled article")[0:160]' <<<"$article") ||
  ! jq -e '.body | type == "string" and length > 0' <<<"$article" >/dev/null; then
  echo "article-summarize: input must be article-scrape JSON with a body" >&2
  exit 2
fi

jq -r '.body' <<<"$article" | summary --format raw --model "$model" --title "$title" "${summary_args[@]}" -
