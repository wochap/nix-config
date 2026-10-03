#!/usr/bin/env bash
# Orchestrates the briefing stages. Every stage writes into the run directory
# and is skipped when its output already exists, so a failed run resumes where
# it stopped (`--from STAGE` forces that stage and the following ones to rerun).

stages=(collect dedup rank enrich write tts package publish)
mode=daily
date=$(date +%F)
from=""
until=""

usage() {
  cat >&2 <<EOF
usage: briefing [--mode daily|weekly] [--date YYYY-MM-DD] [--from STAGE] [--until STAGE]
       briefing ledger ARGS...        (see briefing-ledger --help)

Stages: ${stages[*]}
Run dir: \$BRIEFING_STATE_DIR/runs/<date>-<mode>
Output:  \$BRIEFING_OUT_DIR/<date>-<mode>/
EOF
}

if [[ ${1:-} == ledger ]]; then
  shift
  exec briefing-ledger "$@" --ledger "$BRIEFING_STATE_DIR/ledger.db"
fi

while (($#)); do
  case "$1" in
  --mode) mode=$2; shift 2 ;;
  --mode=*) mode=${1#*=}; shift ;;
  --date) date=$2; shift 2 ;;
  --date=*) date=${1#*=}; shift ;;
  --from) from=$2; shift 2 ;;
  --from=*) from=${1#*=}; shift ;;
  --until) until=$2; shift 2 ;;
  --until=*) until=${1#*=}; shift ;;
  -h | --help) usage; exit 0 ;;
  *) usage; exit 2 ;;
  esac
done

[[ $mode == daily || $mode == weekly ]] || { echo "briefing: bad mode: $mode" >&2; exit 2; }
for stage in "$from" "$until"; do
  [[ -z $stage || " ${stages[*]} " == *" $stage "* ]] || { echo "briefing: unknown stage: $stage" >&2; exit 2; }
done

episode="$date-$mode"
run="$BRIEFING_STATE_DIR/runs/$episode"
publish_dir="$BRIEFING_OUT_DIR/$episode"
ledger="$BRIEFING_STATE_DIR/ledger.db"
profile=$BRIEFING_PROFILE
max_enrich=$(jq -r --arg m "$mode" '.[$m].enrichTop' "$profile")
mkdir -p "$run"

notify() {
  if command -v notify-send >/dev/null && [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    notify-send --app-name=briefing --app-icon=news-feed "$@" || true
  fi
}

failed_stage=""
trap 'notify --urgency=critical "Briefing $episode failed" "stage: ${failed_stage:-?}; see journalctl --user -u briefing-$mode"' ERR

forcing=false

# stage NAME OUTPUT COMMAND...: run COMMAND unless OUTPUT exists (or forced).
stage() {
  local name=$1 output=$2
  shift 2
  [[ $name == "$from" ]] && forcing=true
  if [[ $forcing == false && -e $output ]]; then
    echo "[briefing] $name: done (cached)" >&2
  else
    echo "[briefing] $name: running" >&2
    failed_stage=$name
    rm -rf "$output"
    "$@"
  fi
  if [[ $name == "$until" ]]; then
    echo "[briefing] stopped after $name" >&2
    exit 0
  fi
}

do_collect() {
  rm -rf "$run/collect.tmp"
  briefing-collect --registry "$BRIEFING_REGISTRY" --mode "$mode" --out "$run/collect.tmp"
  mv "$run/collect.tmp" "$run/collect"
}

do_dedup() {
  briefing-ledger seen --ledger "$ledger" --mode "$mode" --exclude-episode "$episode" \
    <"$run/collect/items.jsonl" >"$run/new.jsonl.tmp"
  mv "$run/new.jsonl.tmp" "$run/new.jsonl"
}

do_rank() {
  briefing-rank --profile "$profile" --mode "$mode" --in "$run/new.jsonl" --out "$run/ranked.jsonl"
}

do_enrich() {
  briefing-enrich --in "$run/ranked.jsonl" --out "$run/enriched.jsonl" --top "$max_enrich"
}

do_write() {
  rm -rf "$run/script.tmp"
  briefing-write --profile "$profile" --mode "$mode" --date "$date" \
    --stories "$run/enriched.jsonl" --facts "$run/collect/facts.json" --out "$run/script.tmp"
  mv "$run/script.tmp" "$run/script"
}

do_tts() {
  briefing-tts --chapters "$run/script/chapters.json" --out "$run/audio.tmp"
  mv "$run/audio.tmp" "$run/audio"
}

do_package() {
  local show
  show=$(jq -r '.show' "$profile")
  briefing-package --chapters "$run/script/chapters.json" --audio "$run/audio" \
    --out "$run/episode.mp3" --title "$show ${mode^} $date" --album "$show" --date "$date" \
    ${BRIEFING_COVER:+--cover "$BRIEFING_COVER"}
}

do_publish() {
  local tmp="$publish_dir.tmp"
  rm -rf "$tmp"
  mkdir -p "$tmp"
  cp "$run/episode.mp3" "$tmp/$episode.mp3"
  cp "$run/script/script.md" "$run/script/chapters.json" "$run/script/stories.jsonl" "$tmp/"
  cp "$run/collect/facts.json" "$run/collect/collect-report.json" "$tmp/"
  cp "$run/collect/items.jsonl" "$tmp/sources.jsonl"
  jq -n \
    --arg episode "$episode" --arg mode "$mode" --arg date "$date" \
    --arg model "${BRIEFING_MODEL:-}" --arg voice "${BRIEFING_VOICE:-}" \
    --arg created "$(date -Iseconds)" \
    --slurpfile report "$run/collect/collect-report.json" \
    --argjson items "$(wc -l <"$run/collect/items.jsonl")" \
    --argjson fresh "$(wc -l <"$run/new.jsonl")" \
    --argjson stories "$(wc -l <"$run/script/stories.jsonl")" \
    '{episode: $episode, mode: $mode, date: $date, created: $created, model: $model, voice: $voice,
      counts: {collected: $items, new: $fresh, stories: $stories}, sources: $report[0]}' \
    >"$tmp/manifest.json"
  rm -rf "$publish_dir"
  mv "$tmp" "$publish_dir"
  briefing-ledger record --ledger "$ledger" --episode "$episode" --mode "$mode" \
    --stories "$publish_dir/stories.jsonl"

  # Flat folder for podcast apps (AntennaPod local folders do not recurse).
  if [[ -n ${BRIEFING_LISTEN_DIR:-} ]]; then
    mkdir -p "$BRIEFING_LISTEN_DIR"
    cp "$publish_dir/$episode.mp3" "$BRIEFING_LISTEN_DIR/"
    find "$BRIEFING_LISTEN_DIR" -maxdepth 1 -name '*.mp3' -mtime "+${BRIEFING_LISTEN_KEEP_DAYS:-14}" -delete
  fi
  find "$BRIEFING_STATE_DIR/runs" -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +
  touch "$run/published"
}

stage collect "$run/collect" do_collect
stage dedup "$run/new.jsonl" do_dedup
stage rank "$run/ranked.jsonl" do_rank
stage enrich "$run/enriched.jsonl" do_enrich
stage write "$run/script" do_write
stage tts "$run/audio" do_tts
stage package "$run/episode.mp3" do_package
stage publish "$run/published" do_publish

trap - ERR
minutes=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$publish_dir/$episode.mp3" | awk '{printf "%.0f", $1 / 60}')
notify "Briefing $episode ready" "$minutes min, $(jq -s 'map(select(.used)) | length' "$publish_dir/stories.jsonl") stories"
echo "[briefing] published $publish_dir" >&2
