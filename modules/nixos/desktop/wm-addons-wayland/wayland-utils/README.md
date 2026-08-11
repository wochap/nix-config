# Wayland utilities

## Clipboard text to speech

Enable the local Supertonic service and clipboard command:

```nix
_custom.desktop.wayland-utils = {
  enable = true;
  enableTts = true;
};
```

After applying the NixOS configuration, download the Supertonic 3 model and
voice files into `~/.cache/supertonic3`:

```console
$ supertonic download
```

This setup step is optional. Starting `supertonic.service` with a missing model
downloads the same files automatically. The initial download is about 400 MB,
so the service can take longer than usual to become ready the first time.

Start Supertonic from the Quickshell Control Center before invoking
`tts-clipboard`. The command reports an error instead of starting the service
itself when the service is disabled.

### Usage

The only positional argument is the clipboard selection (`clipboard` or
`primary`). All other options use strict `--key=value` syntax:

```console
$ tts-clipboard                          # Speak the regular clipboard (default)
$ tts-clipboard primary                  # Speak the Wayland primary selection
$ tts-clipboard --stop                   # Stop generation or playback
```

### Input format

The default `auto` input mode prefers HTML when the copying application offers
an HTML clipboard MIME type. Otherwise, it treats the clipboard as
GitHub-flavored Markdown. Pandoc converts the input to readable plain text,
preserving useful paragraph and list structure while removing markup that
Supertonic does not understand.

Select the input format explicitly when automatic detection is not suitable:

```console
$ tts-clipboard --format=raw             # Do not process the clipboard text
$ tts-clipboard --format=markdown        # Interpret text as Markdown
$ tts-clipboard --format=html            # Interpret text as HTML
$ tts-clipboard primary --format=markdown # Options combine with selection
```

Use `raw` for source code, literal markup, or Supertonic expression tags such
as `<laugh>`, `<breath>`, and `<sigh>`. Supertonic does not support HTML,
Markdown, or SSML directly; its expression tags represent nonverbal sounds,
not formatting such as bold or italics.

### Speed

Set any supported speed between `0.7` and `2.0` with `--speed`:

```console
$ tts-clipboard --speed=1.0              # Default
$ tts-clipboard --speed=1.5
$ tts-clipboard primary --speed=1.8
```

Supertonic always synthesizes at `1.0` speed so changing playback speed does
not reduce model quality. The generated audio is played through `mpv`, which
applies pitch-corrected time stretching at the requested speed.

### Inference quality

Set the number of inference steps with `--steps`. Supertonic accepts integers
from `1` through `100`; this command defaults to `3` for low latency. Higher
values generally improve quality at the cost of generation time. Upstream
describes `5` through `12` as the typical quality range.

```console
$ tts-clipboard --steps=2               # Faster, lower quality
$ tts-clipboard --steps=3               # Default
$ tts-clipboard --steps=8               # Upstream default quality
```

### Chunked playback

Application-level chunking is enabled by default. It starts playing the first
sentence-aware chunk while generating the next one. Disable it to submit the
entire selection in one request and wait for the complete response before
playback:

```console
$ tts-clipboard --chunking=on            # Default, lower perceived latency
$ tts-clipboard --chunking=off           # One request and one audio file
```

To inspect the exact text of every request sent to Supertonic, run playback in
the foreground with `--debug`:

```console
$ tts-clipboard --debug --chunking=on
```

The selected clipboard representation and normalization mode are reported
first. Each final chunk is then printed immediately before its request.

### Voice

Supertonic 3 includes five male and five female built-in voices, named `M1`
through `M5` and `F1` through `F5`. `M1` is the default. Select another voice
with `--voice`:

```console
$ tts-clipboard --voice=F2
$ tts-clipboard primary --voice=M4 --speed=1.7
```

The same option accepts the name of an imported custom Supertonic voice.

### Toggle behavior

Invoking `tts-clipboard` while it is already generating or playing also stops
the active operation. Long selections are generated in sentence-aware chunks.
Playback begins after the first chunk, while the following chunk is generated
concurrently. Requests use the native Supertonic endpoint.

The Supertonic service remains running for faster subsequent requests. Stop it
from the Quickshell Control Center or manually when desired:

```console
$ systemctl --user stop supertonic.service
```

Inspect its status and logs with:

```console
$ systemctl --user status supertonic.service
$ journalctl --user --unit=supertonic.service --follow
```
