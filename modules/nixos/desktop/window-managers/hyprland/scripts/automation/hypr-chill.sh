#!/usr/bin/env bash

current_scheme=$(color-scheme print)
video_url="https://www.youtube.com/watch?v=sX6J4t2lRu0"
# VIDEO_URL="https://www.youtube.com/watch?v=_BMi3usEwi8"

# picked by nvim to enable transparent hls
export TRANSPARENT=true

# open terminal
# TODO: manually run `export TRANSPARENT=true`
if [[ "$current_scheme" == "dark" ]]; then
  footclient --app-id=footclient-chill --override colors.alpha=0.75 &
  # footclient --app-id=footclient-chill --override colors.alpha=0.75 --override main.initial-color-theme=dark &
  # foot --app-id=footclient-chill --override colors.alpha=0.75 --override main.initial-color-theme=dark &
else
  kitty --single-instance --app-id=kitty-chill --override background_opacity=0.75 &
fi

# NOTE: foot disables opacity when in fullscreen
# so we fake its state
hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 2, client = 1, window = "class:kitty-chill" }))'
hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 2, client = 1, window = "class:footclient-chill" }))'
hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 2, client = 1, window = "class:foot-chill" }))'

mpvpaper ALL --mpv-options "ytdl-raw-options-append=format=bestvideo no-audio panscan=1 start=5% pause=no loop input-ipc-server=/tmp/mpvpaper-socket" "$video_url"
# NOTE: to switch to a different video
# echo '{ "command": ["loadfile", "$VIDEO_URL", "replace"] }' | socat - /tmp/mpvpaper-socket
