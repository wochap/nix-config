#!/usr/bin/env sh

wid="$1"
class="$2"
instance=$(echo ${3} | xargs)
# title=$(xtitle "$wid")

# Debug
# echo "$wid $class $instance" > /tmp/bspc-external-rules

case "$class" in
  .thunar-wrapped_ )
    case "$(xprop -id "$wid" _NET_WM_WINDOW_TYPE)" in
      *_NET_WM_WINDOW_TYPE_NORMAL* )
        echo state=pseudo_tiled;;
    esac;;
  Nitrogen | zoom | Org.gnome.clocks | Gnome-pomodoro | Gnome-todo | Org.gnome.Nautilus )
    case "$(xprop -id "$wid" _NET_WM_WINDOW_TYPE)" in
      *_NET_WM_WINDOW_TYPE_NORMAL* )
        echo state=pseudo_tiled;;
    esac;;
  Firefox )
    case "$(xprop -id "$wid" WM_WINDOW_ROLE)" in
      *PictureInPicture* )
        echo state=floating sticky=on;;
      *About* )
        echo state=floating center=true;;
    esac;;
esac

case "$(xprop -id "$wid" _NET_WM_WINDOW_TYPE)" in
  *_NET_WM_WINDOW_TYPE_DIALOG* )
    echo state=floating center=true;;
esac;;