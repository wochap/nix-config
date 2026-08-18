#!/usr/bin/env bash
set -euo pipefail

language=""
output_file=""

usage() {
  echo "usage: qwen3-asr-video [--language LANGUAGE] [--output FILE] VIDEO_FILE" >&2
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
  --help | -h)
    usage
    exit 0
    ;;
  --*)
    usage
    exit 2
    ;;
  *)
    if [[ -n ${video_file:-} ]]; then
      usage
      exit 2
    fi
    video_file=$1
    shift
    ;;
  esac
done

if [[ -z ${video_file:-} || ! -f $video_file ]]; then
  echo "qwen3-asr-video: video file does not exist: ${video_file:-<missing>}" >&2
  exit 2
fi

if [[ -z $output_file ]]; then
  output_file="${video_file%.*}.txt"
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/qwen3-asr-video.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

echo "Extracting audio from $video_file" >&2
ffmpeg -nostdin -hide_banner -loglevel error -y \
  -i "$video_file" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$work_dir/audio.wav"

transcribe_args=()
[[ -z $language ]] || transcribe_args+=(--language "$language")

echo "Transcribing with Qwen3-ASR-1.7B on the local NVIDIA service" >&2
qwen3-asr-transcribe "${transcribe_args[@]}" "$work_dir/audio.wav" >"$output_file"
echo "Transcript written to $output_file" >&2
