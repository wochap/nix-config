#!/usr/bin/env bash
# Run coding challenges against an agent/model in a fix-until-green loop.
# Each challenge: challenges/<lang>/<level>-<slug>/{PROMPT.md,deps,check.sh,starter/,tests/}
set -euo pipefail

BENCH_DIR="${LLM_BENCH_DIR:-$(cd "$(dirname "$(readlink -f "$0")")" && pwd)}"
CHALLENGES="$BENCH_DIR/challenges"
CARTRIDGES="${LLM_BENCH_CARTRIDGES:-$BENCH_DIR/../cartridge/skill/cartridges}"
RUNS="${XDG_CACHE_HOME:-$HOME/.cache}/llm-bench"

usage() {
  cat <<USAGE
usage:
  llm-bench run -m <model> [-a pi] [-n 5] [-t 900] [-c] [-o results.tsv] [filter...]
  llm-bench list [filter...]
  llm-bench rank [results.tsv]
  llm-bench validate [filter...]   starter must fail check.sh, solution must pass

run options:
  -m  model passed to \`agents run -m\` (e.g. omniroute/qwen3-4b)
  -a  agent (default: pi)
  -n  max iterations per challenge (default: 5)
  -t  timeout seconds per agent iteration (default: 900)
  -c  inline the language cartridge into the prompt
  -o  results file (default: $RUNS/results.tsv)
filter: substring matched against "<lang>/<level>-<slug>", e.g. zig, go/hard, easy
USAGE
}

list_challenges() {
  local d id f match
  for d in "$CHALLENGES"/*/*/; do
    [[ -f "$d/PROMPT.md" ]] || continue
    id="${d%/}"
    id="${id#"$CHALLENGES"/}"
    if (($# == 0)); then
      echo "$id"
      continue
    fi
    match=0
    for f in "$@"; do [[ "$id" == *"$f"* ]] && match=1; done
    ((match)) && echo "$id"
  done
  return 0
}

# Copy pristine checker and tests so the model cannot edit them away.
restore_protected() {
  local src="$1" work="$2"
  cp -f "$src/check.sh" "$work/check.sh"
  if [[ -d "$src/tests" ]]; then
    rm -rf "$work/tests"
    cp -rT "$src/tests" "$work/tests"
  fi
  # Optional list of starter files (lint/format/compiler configs) to restore too.
  local f
  if [[ -f "$src/protected" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" && "$f" != \#* ]] || continue
      cp -f "$src/starter/$f" "$work/$f"
    done <"$src/protected"
  fi
  chmod -R u+w "$work"
}

build_prompt() {
  local src="$1" lang="$2" cartridge="$3" iter="$4" log="$5"
  if ((cartridge)) && [[ -f "$CARTRIDGES/$lang.md" ]]; then
    cat "$CARTRIDGES/$lang.md"
    printf '\n---\n\n'
  fi
  cat "$src/PROMPT.md"
  cat <<TXT

## Rules
- Work only in the current directory.
- Do not edit \`check.sh\`, \`tests/\` or config files listed in \`protected\`; they are restored before grading.
- Verify with \`bash check.sh\` (format, lint, build, tests). Done means it exits 0.
TXT
  if ((iter > 1)); then
    cat <<TXT

## Previous attempt failed
Files in this directory are your previous attempt. Fix them, do not start over.
Last lines of \`bash check.sh\` output:
\`\`\`
$(tail -n 60 "$log" | cut -c1-200)
\`\`\`
TXT
  fi
}

run_check() {
  local work="$1" log="$2" pkgs=("${@:3}")
  (cd "$work" && timeout 600 nix shell "${pkgs[@]}" -c bash check.sh) >"$log" 2>&1
}

cmd_run() {
  local model="" agent="pi" max=5 tmo=900 cartridge=0 out="$RUNS/results.tsv" opt
  OPTIND=1
  while getopts "m:a:n:t:co:h" opt; do
    case "$opt" in
      m) model="$OPTARG" ;;
      a) agent="$OPTARG" ;;
      n) max="$OPTARG" ;;
      t) tmo="$OPTARG" ;;
      c) cartridge=1 ;;
      o) out="$OPTARG" ;;
      *) usage; exit 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  [[ -n "$model" ]] || { echo "error: -m <model> is required" >&2; exit 1; }

  local stamp ids id src lang work pkgs iter passed start secs tag
  tag="${model//\//_}"
  ((cartridge)) && tag+="-cartridge"
  stamp="$(date +%Y%m%d-%H%M%S)"
  mapfile -t ids < <(list_challenges "$@")
  ((${#ids[@]})) || { echo "error: no challenge matches" >&2; exit 1; }
  mkdir -p "$(dirname "$out")"
  [[ -s "$out" ]] || printf 'date\tagent\tmodel\tcartridge\tchallenge\tpassed\titerations\tseconds\n' >"$out"

  for id in "${ids[@]}"; do
    src="$CHALLENGES/$id"
    lang="${id%%/*}"
    work="$RUNS/runs/$stamp/$tag/$id"
    mkdir -p "$work/.bench"
    [[ -d "$src/starter" ]] && cp -rT "$src/starter" "$work"
    restore_protected "$src" "$work"
    mapfile -t pkgs < <(grep -v '^\s*\(#\|$\)' "$src/deps" | sed 's|^|nixpkgs#|')

    passed=0
    start=$SECONDS
    : >"$work/.bench/check.log"
    for ((iter = 1; iter <= max; iter++)); do
      printf '%s  iter %d/%d  ' "$id" "$iter" "$max" >&2
      build_prompt "$src" "$lang" "$cartridge" "$iter" "$work/.bench/check.log" >"$work/.bench/prompt-$iter.md"
      # Tools from deps are on PATH so the model can run check.sh itself.
      (cd "$work" && timeout "$tmo" nix shell "${pkgs[@]}" -c \
        agents run --json -a "$agent" -m "$model" -C "$work" - <"$work/.bench/prompt-$iter.md") \
        >"$work/.bench/agent-$iter.json" 2>"$work/.bench/agent-$iter.err" || true
      restore_protected "$src" "$work"
      if run_check "$work" "$work/.bench/check.log" "${pkgs[@]}"; then
        passed=1
        echo "PASS" >&2
        break
      fi
      echo "fail at: $(grep '^==> ' "$work/.bench/check.log" | tail -n1)" >&2
    done
    ((passed)) || iter=$max
    secs=$((SECONDS - start))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$stamp" "$agent" "$model" "$cartridge" "$id" "$passed" "$iter" "$secs" >>"$out"
  done
  echo "results: $out" >&2
  echo "workdirs: $RUNS/runs/$stamp" >&2
}

# Score per (agent, model, cartridge): pass count first, then first-try passes, then fewer iterations.
cmd_rank() {
  local file="${1:-$RUNS/results.tsv}"
  [[ -f "$file" ]] || { echo "error: $file not found" >&2; exit 1; }
  awk -F'\t' 'NR > 1 {
      k = $2 "\t" $3 "\t" $4
      key[k] = 1; n[k]++
      if ($6 == 1) { p[k]++; it[k] += $7; if ($7 == 1) p1[k]++ }
    }
    END {
      for (k in key) printf "%d\t%d\t%d\t%.2f\t%s\n", p[k], p1[k], n[k], (p[k] ? it[k] / p[k] : 0), k
    }' "$file" |
    sort -t$'\t' -k1,1nr -k2,2nr -k4,4n |
    awk -F'\t' 'BEGIN { printf "%-4s %-7s %-7s %-9s %-6s %-30s %s\n", "#", "passed", "pass@1", "avg_iter", "agent", "model", "cartridge" }
      { printf "%-4d %-7s %-7d %-9s %-6s %-30s %s\n", NR, $1 "/" $3, $2, $4, $5, $6, $7 }'
}

cmd_validate() {
  local ids id src work pkgs bad=0
  mapfile -t ids < <(list_challenges "$@")
  for id in "${ids[@]}"; do
    src="$CHALLENGES/$id"
    work="$(mktemp -d)"
    mapfile -t pkgs < <(grep -v '^\s*\(#\|$\)' "$src/deps" | sed 's|^|nixpkgs#|')
    [[ -d "$src/starter" ]] && cp -rT "$src/starter" "$work"
    restore_protected "$src" "$work"
    if run_check "$work" "$work/check.log" "${pkgs[@]}"; then
      echo "BAD   $id: starter passes" >&2
      bad=1
    else
      cp -rT "$src/solution" "$work"
      if run_check "$work" "$work/check.log" "${pkgs[@]}"; then
        echo "ok    $id" >&2
      else
        echo "BAD   $id: solution fails at $(grep '^==> ' "$work/check.log" | tail -n1)" >&2
        bad=1
      fi
    fi
    rm -rf "$work"
  done
  return "$bad"
}

case "${1:-}" in
  run) shift; cmd_run "$@" ;;
  list) shift; list_challenges "$@" ;;
  rank) shift; cmd_rank "$@" ;;
  validate) shift; cmd_validate "$@" ;;
  *) usage; [[ "${1:-}" =~ ^(-h|--help)$ ]] || exit 1 ;;
esac
