# Scripts

Helper commands installed by the top-level AI bundle (`_custom.services.ai.enable`).
All three are plain Bash scripts packaged with `writeShellApplication` /
`writeScriptBin`; none of them needs its own enable flag.

## Stack

| Command | Depends on | Purpose |
|---------|-----------|---------|
| `clean-voice` | OmniRoute (`omniroute-chat`), `jq`, `wl-paste`/`wl-copy`, `notify-send` | Clean a raw voice-dictation transcript from the clipboard |
| `summary` | OmniRoute (`omniroute-chat`), `jq`, `pandoc`, `python3` | Summarize a file, inline text, or stdin through OmniRoute |
| `asr-videos` | `qwen3-asr-video` (`enableQwen3Asr`) | Batch-transcribe every MP4 below a directory |

## Setup

`clean-voice` and `summary` need the OmniRoute endpoint key and combo
described in [../omniroute/README.md](../omniroute/README.md). Override the
combo with `OMNIROUTE_MODEL` (default `desktop-free`).

## Usage

### clean-voice

Reads the Wayland clipboard, removes fillers/stutters, adds punctuation, and
copies the cleaned text back:

```sh
clean-voice        # clipboard in → cleaned text out (also copied back)
```

### summary

Accepts a file path, inline content, or `-` for stdin. Returns Markdown with
Summary / Key points / Caveats sections:

```sh
summary notes.txt
summary - < article.md
summary "Some inline text to summarize"
summary --format html page.html
summary --title "Meeting notes" --max-input-tokens 0 notes.txt
OMNIROUTE_MODEL=research-smart summary long-report.md
```

Custom prompts override the built-in `article` preset; `{{content}}` and
`{{title}}` are placeholders:

```sh
summary --system-prompt "You extract action items." \
    --prompt "List the action items.\n\n{{content}}" meeting.md
```

### asr-videos

Transcribes every `*.mp4` below a directory with `qwen3-asr-video`, skipping
files that already have `.txt` and `.json` outputs. Language defaults to
Spanish:

```sh
asr-videos ./lectures
asr-videos --language English ./lectures
asr-videos --num-speakers 2 ./interviews
```

### Shell aliases (with `enableWhisper`)

- `wis FILE` — transcribe a 16 kHz WAV with whisper.cpp to VTT
- `ytaw URL` — download a video and extract its audio as 16 kHz WAV

```sh
ytaw https://www.youtube.com/watch?v=...
wis ./video_wis.wav
```
