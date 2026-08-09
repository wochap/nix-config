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

This setup step is optional. If the model is missing, the first
`tts-clipboard` invocation starts `supertonic.service`, which downloads the
same files automatically. The initial download is about 400 MB, so the first
invocation can take longer than usual.

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
the active operation. The Supertonic service starts on demand and remains
running for faster subsequent requests. Stop it manually when desired:

```console
$ systemctl --user stop supertonic.service
```

Inspect its status and logs with:

```console
$ systemctl --user status supertonic.service
$ journalctl --user --unit=supertonic.service --follow
```
