#!/usr/bin/env bash
set -euo pipefail

# The NixOS module puts ../lib/container.sh, which sets up gpu_args,
# sandbox_args, offline_args, and ensure_image, in front of this script.

language=""
output_file=""
json_output_file=""
num_speakers=""
min_speakers=""
max_speakers=""
diarize=1
validate_output=0

usage() {
  cat >&2 <<'EOF'
usage: asr [OPTIONS] MEDIA_FILE

Transcribe the first audio stream of an audio or video file.

Options:
  --language LANGUAGE      Force an ISO 639 code or English name (default: detect)
  --output, -o FILE        Text transcript path (default: MEDIA_STEM.txt)
  --json-output FILE       Structured result path (default: OUTPUT_STEM.json)
  --no-diarize             Skip word alignment and speaker diarization
  --num-speakers N         Force an exact speaker count
  --min-speakers N         Set the minimum detected speaker count
  --max-speakers N         Set the maximum detected speaker count
  --validate               Validate JSON and print a quality report
  --help, -h               Show this help
EOF
}

die() {
  echo "asr: $*" >&2
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
  --no-diarize)
    diarize=0
    shift
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
    [[ -z ${media_file:-} ]] || { usage; exit 2; }
    media_file=$1
    shift
    ;;
  esac
done

[[ -n ${media_file:-} && -f $media_file ]] || \
  die "media file does not exist: ${media_file:-<missing>}"

for value_name in num_speakers min_speakers max_speakers; do
  value=${!value_name}
  [[ -z $value || $value =~ ^[1-9][0-9]*$ ]] || \
    die "--${value_name//_/-} must be a positive integer"
  [[ -z $value || $diarize == 1 ]] || \
    die "--${value_name//_/-} cannot be combined with --no-diarize"
done
[[ -z $num_speakers || (-z $min_speakers && -z $max_speakers) ]] || \
  die "--num-speakers cannot be combined with --min-speakers or --max-speakers"
[[ -z $min_speakers || -z $max_speakers || $min_speakers -le $max_speakers ]] || \
  die "--min-speakers cannot exceed --max-speakers"

if [[ -n $language ]]; then
  language=$(python3 "$ASR_PIPELINE_SCRIPT" language "$language") || exit 2
fi

if [[ -z $output_file ]]; then
  output_file="${media_file%.*}.txt"
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

# Pinned models by name, read by the pipeline on the host and in the
# container.
ASR_MODELS=$(<"$ASR_MODELS_FILE")
export ASR_MODELS

# Model cache shared by all runs of the selected adapter.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/asr/$ASR_ADAPTER"
mkdir -p "$cache_dir"

roles=transcriber
((diarize == 0)) || roles=transcriber,aligner,diarizer
models_cached=0
if python3 "$ASR_PIPELINE_SCRIPT" models-cached --cache-dir "$cache_dir" --roles "$roles"; then
  models_cached=1
fi

if [[ -z ${HF_TOKEN:-} && -n ${ASR_HF_TOKEN_FILE:-} && -r $ASR_HF_TOKEN_FILE ]]; then
  HF_TOKEN=$(<"$ASR_HF_TOKEN_FILE")
  export HF_TOKEN
fi

if [[ $diarize == 1 && ${ASR_OFFLINE:-0} != 1 && $models_cached != 1 && -z ${HF_TOKEN:-} ]]; then
  die "HF_TOKEN is required; accept the pyannote Community-1 model terms first"
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/asr.XXXXXX")
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

echo "Extracting mono 16 kHz audio from $media_file" >&2
ffmpeg -nostdin -hide_banner -loglevel error -y \
  -i "$media_file" -map 0:a:0 -vn -ac 1 -ar 16000 -c:a pcm_s16le \
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

# ROCm's PyTorch exposes AMD GPUs through the CUDA API, so both accelerators
# use the same device string.
container_args=(
  run
  --rm
  "${gpu_args[@]}"
  "${sandbox_args[@]}"
  --entrypoint=python3
  --env=ASR_DEVICE=cuda:0
  --env=ASR_DTYPE
  --env=ASR_BATCH_SIZE
  --env=ASR_ADAPTER
  --env=ASR_MODELS
  --env=HF_HUB_DISABLE_TELEMETRY=1
  # Prefer the cache quickly when Hugging Face is unreachable. Strict offline
  # operation remains available through ASR_OFFLINE=1.
  --env=HF_HUB_ETAG_TIMEOUT=2
  --env=MPLCONFIGDIR=/tmp/matplotlib
  --volume="$cache_dir:/root/.cache:rw"
  --volume="$work_dir:/input:ro"
  --volume="$state_dir:/state:rw"
  --volume="$ASR_PIPELINE_SCRIPT:/opt/asr/pipeline.py:ro"
  --volume="$ASR_ADAPTER_MODULE:/opt/asr/adapter.py:ro"
)
if [[ $AI_ACCELERATOR == rocm ]]; then
  # MIOpen writes its kernel databases under ~/.config by default, which the
  # read-only rootfs rejects. Keep them next to the model cache so compiled
  # kernels survive between runs.
  container_args+=(--env=MIOPEN_USER_DB_PATH=/root/.cache/miopen/db)
fi

if [[ ${ASR_OFFLINE:-0} == 1 || $models_cached == 1 ]]; then
  container_args+=("${offline_args[@]}")
  if [[ ${ASR_OFFLINE:-0} != 1 ]]; then
    echo "Pinned models are cached; running without Hugging Face network access" >&2
  fi
elif [[ -n ${HF_TOKEN:-} ]]; then
  container_args+=(--env=HF_TOKEN)
fi

source_id="$(realpath "$media_file")|$(stat --format='%s:%Y' "$media_file")"
python_args=(/opt/asr/pipeline.py infer --audio-dir /input --state-dir /state --source-name "$(basename "$media_file")" --source-id "$source_id")
[[ -z $language ]] || python_args+=(--language "$language")
[[ -z $num_speakers ]] || python_args+=(--num-speakers "$num_speakers")
[[ -z $min_speakers ]] || python_args+=(--min-speakers "$min_speakers")
[[ -z $max_speakers ]] || python_args+=(--max-speakers "$max_speakers")
if ((diarize)); then
  echo "Running ASR, word alignment, and speaker diarization sequentially" >&2
else
  python_args+=(--no-diarize)
  echo "Running ASR" >&2
fi

podman "${container_args[@]}" "$AI_IMAGE" \
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
