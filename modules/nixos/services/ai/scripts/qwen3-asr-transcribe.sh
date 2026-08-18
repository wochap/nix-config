#!/usr/bin/env bash
set -euo pipefail

language=""

usage() {
  echo "usage: qwen3-asr-transcribe [--language LANGUAGE] AUDIO_FILE" >&2
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
    if [[ -n ${audio_file:-} ]]; then
      usage
      exit 2
    fi
    audio_file=$1
    shift
    ;;
  esac
done

if [[ -z ${audio_file:-} || ! -f $audio_file ]]; then
  echo "qwen3-asr-transcribe: audio file does not exist: ${audio_file:-<missing>}" >&2
  exit 2
fi

audio_file=$(realpath "$audio_file")
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
  --volume="$audio_file:/input/audio:ro"
  --volume="$cache_dir:/root/.cache:rw"
  --volume="$QWEN3_ASR_SCRIPT:/opt/qwen3-asr/transcribe.py:ro"
)

if [[ ${QWEN3_ASR_OFFLINE:-0} == 1 ]]; then
  container_args+=(
    --network=none
    --env=HF_HUB_OFFLINE=1
    --env=TRANSFORMERS_OFFLINE=1
  )
fi

python_args=(
  /opt/qwen3-asr/transcribe.py
  /input/audio
)
[[ -z $language ]] || python_args+=(--language "$language")

exec podman "${container_args[@]}" "$QWEN3_ASR_IMAGE" "${python_args[@]}"
