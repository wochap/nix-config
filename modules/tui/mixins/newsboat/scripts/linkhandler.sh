#!/usr/bin/env bash

[ -z "$1" ] && {
  xdg-open
  exit
}

case "$1" in
*mkv | *webm | *mp4 | *youtube.com/watch* | *youtube.com/playlist* | *youtube.com/shorts* | *youtu.be* | *hooktube.com* | *bitchute.com* | *videos.lukesmith.xyz* | *odysee.com*)
  setsid -f mpv -quiet "$1" >/dev/null 2>&1
  ;;
*png | *jpg | *jpe | *jpeg | *gif | *webp)
  curl -sL "$1" >"/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")" && imv "/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")" >/dev/null 2>&1 &
  ;;
*pdf | *cbz | *cbr)
  curl -sL "$1" >"/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")" && zathura "/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")" >/dev/null 2>&1 &
  ;;
*mp3 | *flac | *opus | *mp3?source*)
  qndl "$1" 'curl -LO' >/dev/null 2>&1
  ;;
*)
  [ -f "$1" ] && setsid -f "$TERMINAL" -e "$EDITOR" "$1" >/dev/null 2>&1 || setsid -f xdg-open "$1" >/dev/null 2>&1
  ;;
esac
