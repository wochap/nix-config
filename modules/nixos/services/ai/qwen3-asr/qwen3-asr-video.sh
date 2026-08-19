#!/usr/bin/env bash
set -euo pipefail

language=""
output_file=""
json_output_file=""
num_speakers=""
min_speakers=""
max_speakers=""

usage() {
  cat >&2 <<'EOF'
usage: qwen3-asr-video [OPTIONS] VIDEO_FILE

Options:
  --language LANGUAGE      Force a language name or ISO code (default: detect)
  --output, -o FILE        Text transcript path (default: VIDEO_STEM.txt)
  --json-output FILE       Structured result path (default: OUTPUT_STEM.json)
  --num-speakers N         Force an exact speaker count
  --min-speakers N         Set the minimum detected speaker count
  --max-speakers N         Set the maximum detected speaker count
  --help, -h               Show this help
EOF
}

die() {
  echo "qwen3-asr-video: $*" >&2
  exit 2
}

while (($#)); do
  case "$1" in
  --language)
    (($# >= 2)) || { usage; exit 2; }
    language=$2
    shift 2
    ;;
  --output | -o)
    (($# >= 2)) || { usage; exit 2; }
    output_file=$2
    shift 2
    ;;
  --json-output)
    (($# >= 2)) || { usage; exit 2; }
    json_output_file=$2
    shift 2
    ;;
  --num-speakers)
    (($# >= 2)) || { usage; exit 2; }
    num_speakers=$2
    shift 2
    ;;
  --min-speakers)
    (($# >= 2)) || { usage; exit 2; }
    min_speakers=$2
    shift 2
    ;;
  --max-speakers)
    (($# >= 2)) || { usage; exit 2; }
    max_speakers=$2
    shift 2
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  --*)
    usage
    exit 2
    ;;
  *)
    [[ -z ${video_file:-} ]] || { usage; exit 2; }
    video_file=$1
    shift
    ;;
  esac
done

[[ -n ${video_file:-} && -f $video_file ]] || \
  die "video file does not exist: ${video_file:-<missing>}"

for value_name in num_speakers min_speakers max_speakers; do
  value=${!value_name}
  [[ -z $value || $value =~ ^[1-9][0-9]*$ ]] || \
    die "--${value_name//_/-} must be a positive integer"
done
[[ -z $num_speakers || (-z $min_speakers && -z $max_speakers) ]] || \
  die "--num-speakers cannot be combined with --min-speakers or --max-speakers"
[[ -z $min_speakers || -z $max_speakers || $min_speakers -le $max_speakers ]] || \
  die "--min-speakers cannot exceed --max-speakers"

if [[ -z $output_file ]]; then
  output_file="${video_file%.*}.txt"
fi
if [[ -z $json_output_file ]]; then
  json_output_file="${output_file%.*}.json"
fi
[[ $output_file != "$json_output_file" ]] || die "text and JSON output paths must differ"

output_dir=$(dirname "$output_file")
json_output_dir=$(dirname "$json_output_file")
[[ -d $output_dir ]] || die "output directory does not exist: $output_dir"
[[ -d $json_output_dir ]] || die "JSON output directory does not exist: $json_output_dir"

chunk_seconds=${QWEN3_ASR_CHUNK_SECONDS:-240}
[[ $chunk_seconds =~ ^[1-9][0-9]*$ ]] || \
  die "QWEN3_ASR_CHUNK_SECONDS must be a positive integer"

if [[ -z ${HF_TOKEN:-} && -n ${QWEN3_ASR_HF_TOKEN_FILE:-} && -r $QWEN3_ASR_HF_TOKEN_FILE ]]; then
  HF_TOKEN=$(<"$QWEN3_ASR_HF_TOKEN_FILE")
  export HF_TOKEN
fi

if [[ ${QWEN3_ASR_OFFLINE:-0} != 1 && -z ${HF_TOKEN:-} ]]; then
  die "HF_TOKEN is required; accept the pyannote Community-1 model terms first"
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/qwen3-asr-video.XXXXXX")
text_tmp=$(mktemp "$output_dir/.qwen3-asr-text.XXXXXX")
json_tmp=$(mktemp "$json_output_dir/.qwen3-asr-json.XXXXXX")
cleanup() {
  rm -rf -- "$work_dir"
  rm -f -- "$text_tmp" "$json_tmp"
}
trap cleanup EXIT

echo "Extracting mono 16 kHz audio from $video_file" >&2
ffmpeg -nostdin -hide_banner -loglevel error -y \
  -i "$video_file" -map 0:a:0 -vn -ac 1 -ar 16000 -c:a pcm_s16le \
  "$work_dir/full.wav"

ffmpeg -nostdin -hide_banner -loglevel error -y \
  -i "$work_dir/full.wav" -map 0:a:0 -c:a pcm_s16le \
  -f segment -segment_time "$chunk_seconds" -reset_timestamps 1 \
  "$work_dir/chunk-%05d.wav"

if ! podman image exists "$QWEN3_ASR_DIARIZATION_IMAGE"; then
  echo "Building the pinned Qwen + pyannote inference image (first run only)" >&2
  podman build --pull=missing --tag "$QWEN3_ASR_DIARIZATION_IMAGE" \
    "$QWEN3_ASR_DIARIZATION_CONTEXT"
fi

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/qwen3-asr"
mkdir -p "$cache_dir"

container_args=(
  run
  --rm
  --device=nvidia.com/gpu=all
  --cap-drop=all
  --security-opt=no-new-privileges
  --read-only
  --entrypoint=python3
  "--tmpfs=/tmp:rw,nosuid,nodev,size=4g"
  --pids-limit=2048
  --shm-size=4g
  --env=HF_HUB_DISABLE_TELEMETRY=1
  --env=MPLCONFIGDIR=/tmp/matplotlib
  --volume="$cache_dir:/root/.cache:rw"
  --volume="$work_dir:/input:ro"
  --volume="$QWEN3_ASR_PIPELINE_SCRIPT:/opt/qwen3-asr/pipeline.py:ro"
)

if [[ ${QWEN3_ASR_OFFLINE:-0} == 1 ]]; then
  container_args+=(
    --network=none
    --env=HF_HUB_OFFLINE=1
    --env=TRANSFORMERS_OFFLINE=1
  )
elif [[ -n ${HF_TOKEN:-} ]]; then
  container_args+=(--env=HF_TOKEN)
fi

python_args=(/opt/qwen3-asr/pipeline.py infer --audio-dir /input --source-name "$(basename "$video_file")")
[[ -z $language ]] || python_args+=(--language "$language")
[[ -z $num_speakers ]] || python_args+=(--num-speakers "$num_speakers")
[[ -z $min_speakers ]] || python_args+=(--min-speakers "$min_speakers")
[[ -z $max_speakers ]] || python_args+=(--max-speakers "$max_speakers")

echo "Running ASR, forced alignment, and speaker diarization sequentially" >&2
podman "${container_args[@]}" "$QWEN3_ASR_DIARIZATION_IMAGE" \
  "${python_args[@]}" >"$json_tmp"

python3 "$QWEN3_ASR_PIPELINE_SCRIPT" render --input "$json_tmp" >"$text_tmp"
mv -f -- "$json_tmp" "$json_output_file"
mv -f -- "$text_tmp" "$output_file"

echo "Transcript written to $output_file" >&2
echo "Structured result written to $json_output_file" >&2
