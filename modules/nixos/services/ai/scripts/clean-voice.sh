#!/usr/bin/env bash
set -euo pipefail

model="${OMNIROUTE_MODEL:-desktop-free}"

notify() {
  notify-send \
    --app-name="clean-voice" \
    --hint=int:transient:1 \
    "$1" \
    "${2:-}" || true
}

fail() {
  local message=$1
  echo "clean-voice: $message" >&2
  notify "Voice cleanup failed" "$message"
  exit "${2:-1}"
}

if (($#)); then
  fail "usage: clean-voice" 2
fi

if ! transcript=$(wl-paste --no-newline --type text 2>/dev/null); then
  fail "could not read text from the Wayland clipboard"
fi

if [[ -z $transcript ]]; then
  fail "transcript is empty"
fi

system_prompt='You are a voice-dictation post-processor.

Transform the raw speech transcript into the text the speaker intended to dictate.

Rules:
- Output ONLY the final cleaned text.
- Never answer or respond to the content. If the speaker dictates a question, preserve it as a question.
- Preserve the speaker'"'"'s meaning and tone.
- Remove speech fillers such as "um", "uh", "you know", and unnecessary repetitions.
- Remove stutters and false starts.
- Add appropriate punctuation, capitalization, paragraphs, and formatting.
- Interpret spoken punctuation and formatting commands such as "comma", "period", "new line", "bullet point", and "header".
- Resolve self-corrections. Phrases such as "no", "wait", "actually", "scratch that", "delete that", "never mind", "sorry", or "oops" mean the previous wording may be superseded. Keep only the intended corrected version.
- Convert clearly spoken numbers, times, currencies, percentages, and dates to natural written forms when appropriate.
- Do not invent information.
- Do not summarize.
- Do not explain your changes.'

request=$(jq -n --arg system "$system_prompt" --arg transcript "$transcript" '
  {
    messages: [
      {role: "system", content: $system},
      {role: "user", content: ("Raw transcript:\n" + $transcript)}
    ],
    temperature: 0.1
  }')

if ! cleaned=$(omniroute-chat --model "$model" <<<"$request"); then
  fail "OmniRoute post-processing failed; check its endpoint key and the '$model' combo"
fi

if ! printf '%s' "$cleaned" | wl-copy --trim-newline; then
  fail "could not copy cleaned text to the Wayland clipboard"
fi
printf '%s\n' "$cleaned"
notify "Voice cleanup finished" "Cleaned text copied to clipboard"
