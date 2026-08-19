#!/usr/bin/env bash
set -euo pipefail

language=""
audio_files=()

usage() {
  echo "usage: qwen3-asr-transcribe [--language LANGUAGE] AUDIO_FILE..." >&2
}

while (($#)); do
  case "$1" in
  --language)
    (($# >= 2)) || {
      usage
      exit 2
    }
    language=$2
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
    audio_files+=("$1")
    shift
    ;;
  esac
done

if ((${#audio_files[@]} == 0)); then
  echo "qwen3-asr-transcribe: no audio files provided" >&2
  exit 2
fi

for i in "${!audio_files[@]}"; do
  if [[ ! -f ${audio_files[i]} ]]; then
    echo "qwen3-asr-transcribe: audio file does not exist: ${audio_files[i]}" >&2
    exit 2
  fi
  audio_files[i]=$(realpath "${audio_files[i]}")
done

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
  --volume="$cache_dir:/root/.cache:rw"
  --volume="$QWEN3_ASR_SCRIPT:/opt/qwen3-asr/transcribe.py:ro"
)

python_args=(/opt/qwen3-asr/transcribe.py)
for i in "${!audio_files[@]}"; do
  container_audio=$(printf '/input/audio-%05d' "$i")
  container_args+=(--volume="${audio_files[i]}:$container_audio:ro")
  python_args+=("$container_audio")
done

if [[ ${QWEN3_ASR_OFFLINE:-0} == 1 ]]; then
  container_args+=(
    --network=none
    --env=HF_HUB_OFFLINE=1
    --env=TRANSFORMERS_OFFLINE=1
  )
fi

[[ -z $language ]] || python_args+=(--language "$language")

exec podman "${container_args[@]}" "$QWEN3_ASR_IMAGE" "${python_args[@]}"
