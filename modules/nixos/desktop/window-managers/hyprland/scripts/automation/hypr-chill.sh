#!/usr/bin/env bash

CURRENT_SCHEME=$(color-scheme print)
VIDEO_URL="https://www.youtube.com/watch?v=sX6J4t2lRu0"

# picked by nvim to enable transparent hls
export TRANSPARENT=true

if [[ "$CURRENT_SCHEME" == "dark" ]]; then
  kitty --app-id=kitty-chill --override background=#1e1e2e --override background_opacity=0.75 &
else
  # TODO: manually run `export TRANSPARENT=true`
  footclient --app-id=foor-chill --override colors.background=1e1e2e --override colors.alpha=0.75 &
fi

mpvpaper ALL --mpv-options "--ytdl-raw-options=format=bv --no-audio --panscan=1 --start=5% --pause=no --loop --input-ipc-server=/tmp/mpvpaper-socket" "$VIDEO_URL"
