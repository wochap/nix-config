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

Use the clipboard command with:

```console
$ tts-clipboard           # Speak the regular clipboard
$ tts-clipboard primary   # Speak the Wayland primary selection
$ tts-clipboard stop      # Stop generation or playback
```

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
