#!/usr/bin/env bash
set -euo pipefail

language=""
output_file=""
json_output_file=""
num_speakers=""
min_speakers=""
max_speakers=""
validate_output=0

usage() {
  cat >&2 <<'EOF'
usage: asr-video [OPTIONS] VIDEO_FILE

Options:
  --language LANGUAGE      Force a language name or ISO code (default: detect)
  --output, -o FILE        Text transcript path (default: VIDEO_STEM.txt)
  --json-output FILE       Structured result path (default: OUTPUT_STEM.json)
  --num-speakers N         Force an exact speaker count
  --min-speakers N         Set the minimum detected speaker count
  --max-speakers N         Set the maximum detected speaker count
  --validate               Validate JSON and print a quality report
  --help, -h               Show this help
EOF
}

die() {
  echo "asr-video: $*" >&2
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
  --validate)
    validate_output=1
    shift
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

chunk_seconds=${ASR_CHUNK_SECONDS:-$ASR_DEFAULT_CHUNK_SECONDS}
[[ $chunk_seconds =~ ^[1-9][0-9]*$ ]] || \
  die "ASR_CHUNK_SECONDS must be a positive integer"

read -r -a model_files <<<"$ASR_TRANSCRIBER_FILES $ASR_ALIGNER_FILES"
diarizer_snapshot="huggingface/hub/models--pyannote--speaker-diarization-community-1/snapshots/$ASR_DIARIZER_REVISION"
model_files+=(
  "$diarizer_snapshot/config.yaml"
  "$diarizer_snapshot/segmentation/pytorch_model.bin"
  "$diarizer_snapshot/embedding/pytorch_model.bin"
)
models_cached=0
if files_cached "${model_files[@]}"; then
  models_cached=1
fi

if [[ -z ${HF_TOKEN:-} && -n ${ASR_HF_TOKEN_FILE:-} && -r $ASR_HF_TOKEN_FILE ]]; then
  HF_TOKEN=$(<"$ASR_HF_TOKEN_FILE")
  export HF_TOKEN
fi

if [[ ${ASR_OFFLINE:-0} != 1 && $models_cached != 1 && -z ${HF_TOKEN:-} ]]; then
  die "HF_TOKEN is required; accept the pyannote Community-1 model terms first"
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/asr-video.XXXXXX")
text_tmp=$(mktemp "$output_dir/.asr-text.XXXXXX")
json_tmp=$(mktemp "$json_output_dir/.asr-json.XXXXXX")
state_dir="${json_output_file}.asr-state"
mkdir -p "$state_dir"
state_dir=$(realpath "$state_dir")
cleanup() {
  rm -rf -- "$work_dir"
  rm -f -- "$text_tmp" "$json_tmp"
}
trap cleanup EXIT

echo "Extracting mono 16 kHz audio from $video_file" >&2
ffmpeg -nostdin -hide_banner -loglevel error -y \
  -i "$video_file" -map 0:a:0 -vn -ac 1 -ar 16000 -c:a pcm_s16le \
  "$work_dir/full.wav"

chunk_plan=$(python3 "$ASR_PIPELINE_SCRIPT" plan-chunks \
  --input "$work_dir/full.wav" \
  --max-seconds "$chunk_seconds" \
  --search-seconds "${ASR_SILENCE_SEARCH_SECONDS:-30}" \
  --min-silence-seconds "${ASR_MIN_SILENCE_SECONDS:-0.4}" \
  --silence-db "${ASR_SILENCE_DB:--35}")
if [[ -n $chunk_plan ]]; then
  ffmpeg -nostdin -hide_banner -loglevel error -y \
    -i "$work_dir/full.wav" -map 0:a:0 -c:a pcm_s16le \
    -f segment -segment_times "$chunk_plan" -reset_timestamps 1 \
    "$work_dir/chunk-%05d.wav"
else
  cp -- "$work_dir/full.wav" "$work_dir/chunk-00000.wav"
fi

ensure_image

container_args=(
  run
  --rm
  "${gpu_args[@]}"
  --cap-drop=all
  --security-opt=no-new-privileges
  --read-only
  --entrypoint=python3
  "--tmpfs=/tmp:rw,nosuid,nodev,size=$ASR_TMP_SIZE"
  --pids-limit=2048
  --shm-size="$ASR_SHM_SIZE"
  --env=HF_HUB_DISABLE_TELEMETRY=1
  # Prefer the cache quickly when Hugging Face is unreachable. Strict offline
  # operation remains available through ASR_OFFLINE=1.
  --env=HF_HUB_ETAG_TIMEOUT=2
  --env=ASR_DIARIZER_REVISION
  --env=MPLCONFIGDIR=/tmp/matplotlib
  --volume="$cache_dir:/root/.cache:rw"
  --volume="$work_dir:/input:ro"
  --volume="$state_dir:/state:rw"
  --volume="$ASR_PIPELINE_SCRIPT:/opt/asr/pipeline.py:ro"
)

if [[ ${ASR_OFFLINE:-0} == 1 || $models_cached == 1 ]]; then
  container_args+=(
    --network=none
    --env=HF_HUB_OFFLINE=1
    --env=TRANSFORMERS_OFFLINE=1
  )
  if [[ ${ASR_OFFLINE:-0} != 1 ]]; then
    echo "Pinned models are cached; running without Hugging Face network access" >&2
  fi
elif [[ -n ${HF_TOKEN:-} ]]; then
  container_args+=(--env=HF_TOKEN)
fi

source_id="$(realpath "$video_file")|$(stat --format='%s:%Y' "$video_file")"
python_args=(/opt/asr/pipeline.py infer --audio-dir /input --state-dir /state --source-name "$(basename "$video_file")" --source-id "$source_id")
[[ -z $language ]] || python_args+=(--language "$language")
[[ -z $num_speakers ]] || python_args+=(--num-speakers "$num_speakers")
[[ -z $min_speakers ]] || python_args+=(--min-speakers "$min_speakers")
[[ -z $max_speakers ]] || python_args+=(--max-speakers "$max_speakers")

echo "Running ASR, forced alignment, and speaker diarization sequentially" >&2
podman "${container_args[@]}" "$ASR_IMAGE" \
  "${python_args[@]}" >"$json_tmp"

if ((validate_output)); then
  python3 "$ASR_PIPELINE_SCRIPT" validate --input "$json_tmp"
fi
python3 "$ASR_PIPELINE_SCRIPT" render --input "$json_tmp" >"$text_tmp"
mv -f -- "$json_tmp" "$json_output_file"
mv -f -- "$text_tmp" "$output_file"
rm -rf -- "$state_dir"

echo "Transcript written to $output_file" >&2
echo "Structured result written to $json_output_file" >&2
