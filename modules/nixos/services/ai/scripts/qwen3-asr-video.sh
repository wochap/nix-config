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

# Keep each inference small enough for an 8 GB GPU. This does not change the
# audio format, model, or precision; it only bounds the temporary memory used
# while the model is generating a transcript.
chunk_seconds=${QWEN3_ASR_CHUNK_SECONDS:-240}
if [[ ! $chunk_seconds =~ ^[1-9][0-9]*$ ]]; then
  echo "qwen3-asr-video: QWEN3_ASR_CHUNK_SECONDS must be a positive integer" >&2
  exit 2
fi

echo "Extracting audio from $video_file in ${chunk_seconds}-second chunks" >&2
ffmpeg -nostdin -hide_banner -loglevel error -y \
  -i "$video_file" -map 0:a:0 -vn -ac 1 -ar 16000 -c:a pcm_s16le \
  -f segment -segment_time "$chunk_seconds" -reset_timestamps 1 \
  "$work_dir/audio-%05d.wav"

transcribe_args=()
[[ -z $language ]] || transcribe_args+=(--language "$language")

audio_chunks=("$work_dir"/audio-*.wav)
transcript_file="$work_dir/transcript.txt"
: >"$transcript_file"

echo "Transcribing ${#audio_chunks[@]} chunks with Qwen3-ASR-1.7B on the local NVIDIA service" >&2
for i in "${!audio_chunks[@]}"; do
  echo "Transcribing chunk $((i + 1))/${#audio_chunks[@]}" >&2
  qwen3-asr-transcribe "${transcribe_args[@]}" "${audio_chunks[$i]}" >>"$transcript_file"
done

mv "$transcript_file" "$output_file"
echo "Transcript written to $output_file" >&2
