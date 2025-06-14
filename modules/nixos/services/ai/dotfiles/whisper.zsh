function extract_for_whisper() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: extract_audio <input_video_file>"
    return 1
  fi

  local input_file="$1"
  local output_file="./$(basename "${input_file%.*}_wis.wav")"

  if [[ ! -f "$input_file" ]]; then
    echo "Error: File '$input_file' not found."
    return 1
  fi

  ffmpeg -i "$input_file" -acodec pcm_s16le -ar 16000 "$output_file"
}
compdef _files extract_for_whisper

