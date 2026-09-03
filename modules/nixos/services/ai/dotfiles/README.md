# Dotfiles

## whisper.zsh

Defines `extract_for_whisper`, which converts any video/audio file to a
16 kHz mono WAV suitable for whisper.cpp:

```sh
extract_for_whisper lecture.mp4   # writes ./lecture_wis.wav
wis ./lecture_wis.wav             # alias from the AI bundle (needs enableWhisper)
```
