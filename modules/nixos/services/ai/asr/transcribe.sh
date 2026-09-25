#!/usr/bin/env bash
set -euo pipefail

language=""
audio_files=()

usage() {
  echo "usage: asr-transcribe [--language LANGUAGE] AUDIO_FILE..." >&2
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
  echo "asr-transcribe: no audio files provided" >&2
  exit 2
fi

for i in "${!audio_files[@]}"; do
  if [[ ! -f ${audio_files[i]} ]]; then
    echo "asr-transcribe: audio file does not exist: ${audio_files[i]}" >&2
    exit 2
  fi
  audio_files[i]=$(realpath "${audio_files[i]}")
done

read -r -a transcriber_files <<<"$ASR_TRANSCRIBER_FILES"
asr_cached=0
if files_cached "${transcriber_files[@]}"; then
  asr_cached=1
fi

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
  --env=HF_HUB_ETAG_TIMEOUT=2
  --volume="$cache_dir:/root/.cache:rw"
  --volume="$ASR_SCRIPT:/opt/asr/transcribe.py:ro"
)

python_args=(/opt/asr/transcribe.py)
for i in "${!audio_files[@]}"; do
  container_audio=$(printf '/input/audio-%05d' "$i")
  container_args+=(--volume="${audio_files[i]}:$container_audio:ro")
  python_args+=("$container_audio")
done

if [[ ${ASR_OFFLINE:-0} == 1 || $asr_cached == 1 ]]; then
  container_args+=(
    --network=none
    --env=HF_HUB_OFFLINE=1
    --env=TRANSFORMERS_OFFLINE=1
  )
  if [[ ${ASR_OFFLINE:-0} != 1 ]]; then
    echo "Pinned ASR model is cached; running without Hugging Face network access" >&2
  fi
fi

[[ -z $language ]] || python_args+=(--language "$language")

ensure_image
exec podman "${container_args[@]}" "$ASR_IMAGE" "${python_args[@]}"
