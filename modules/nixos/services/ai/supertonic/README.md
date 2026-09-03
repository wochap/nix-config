# Supertonic

Enable the local Supertonic service and clipboard command:

```nix
_custom.services.ai = {
  enable = true;
  enableSupertonic = true;
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
`supertonic-speak` or `supertonic-clipboard`. The commands report an error
instead of starting the service itself when the service is disabled.

## Usage

`supertonic-speak` accepts either a text string or a path to a text file.
`supertonic-clipboard` reads the regular clipboard by default and accepts
`primary` to read the middle-click selection. All options use strict
`--key=value` syntax and are shared by both commands:

```console
$ supertonic-speak "Text to speak"
$ supertonic-speak ./article.md          # Speak the contents of a file
$ supertonic-clipboard                   # Speak the regular clipboard (default)
$ supertonic-clipboard primary           # Speak the primary selection
$ supertonic-speak --pause               # Pause generation and playback
$ supertonic-speak --resume              # Resume generation and playback
$ supertonic-speak --toggle-pause        # Toggle pause; no-op when idle
$ supertonic-speak --stop                # Stop generation or playback
```

Literal text passed to `supertonic-speak` defaults to `raw`. For files,
`file --mime-type` detects HTML from its contents, including extensionless
files. Because Markdown is normally reported as plain text, `.md` and
`.markdown` files use Markdown; other files use raw text. An explicit
`--format` always overrides this inference.

## Input format

The default `auto` input mode prefers HTML when the copying application offers
an HTML clipboard MIME type. Otherwise, it treats the clipboard as
GitHub-flavored Markdown. Pandoc converts the input to readable plain text,
preserving useful paragraph and list structure while removing markup that
Supertonic does not understand.

Select the input format explicitly when automatic detection is not suitable:

```console
$ supertonic-speak code.txt --format=raw # Do not process the input text
$ supertonic-speak README.md --format=markdown
$ supertonic-speak page.html --format=html
$ supertonic-clipboard primary --format=markdown
```

Use `raw` for source code, literal markup, or Supertonic expression tags such
as `<laugh>`, `<breath>`, and `<sigh>`. Supertonic does not support HTML,
Markdown, or SSML directly; its expression tags represent nonverbal sounds,
not formatting such as bold or italics.

## Speed

Set any supported speed between `0.7` and `2.0` with `--speed`:

```console
$ supertonic-clipboard --speed=1.0       # Default
$ supertonic-speak article.md --speed=1.5
$ supertonic-clipboard primary --speed=1.8
```

Supertonic always synthesizes at `1.0` speed so changing playback speed does
not reduce model quality. The generated audio is played through `mpv`, which
applies pitch-corrected time stretching at the requested speed.

## Inference quality

Set the number of inference steps with `--steps`. Supertonic accepts integers
from `1` through `100`; this command defaults to `5`. Higher
values generally improve quality at the cost of generation time. Upstream
describes `5` through `12` as the typical quality range.

```console
$ supertonic-clipboard --steps=2         # Faster, lower quality
$ supertonic-clipboard --steps=5         # Default
$ supertonic-speak article.md --steps=8  # Upstream default quality
```

## Chunked playback

Application-level chunking is enabled by default. It starts playing the first
sentence-aware chunk while generating the next one. Disable it to submit the
entire selection in one request and wait for the complete response before
playback:

```console
$ supertonic-clipboard --chunking=on     # Default, lower perceived latency
$ supertonic-clipboard --chunking=off    # One request and one audio file
```

To inspect the exact text of every request sent to Supertonic, run playback in
the foreground with `--debug`:

```console
$ supertonic-clipboard --debug --chunking=on
```

The normalization mode is reported first. Each final chunk is then printed
immediately before its request.

## Voice

Supertonic 3 includes five male and five female built-in voices, named `M1`
through `M5` and `F1` through `F5`. `M1` is the default. Select another voice
with `--voice`:

```console
$ supertonic-clipboard --voice=F2
$ supertonic-clipboard primary --voice=M4 --speed=1.7
```

The same option accepts the name of an imported custom Supertonic voice.

## Toggle behavior

Invoking either command while speech is already generating or playing stops
the active operation. Long inputs are generated in sentence-aware chunks.
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
