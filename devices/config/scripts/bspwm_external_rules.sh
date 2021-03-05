#!/usr/bin/env sh

wid="$1"
class="$2"
instance=$(echo ${3} | xargs)
# title=$(xtitle "$wid")

# Debug
# echo "$wid $class $instance" > /tmp/bspc-external-rules

screenheight=$(xdpyinfo | awk -F'[ x]+' '/dimensions:/{print $4}')
# screenwidth=$(xdpyinfo | awk -F'[ x]+' '/dimensions:/{print $3}')
screenwidth=$(xrandr | grep primary | awk '{print $4}' | cut -d 'x' -f 1)
windowwidth=$(echo "$screenwidth"/2.75 | bc)
windowheight=$(echo "$screenheight"/2.5 | bc)
windowx=$(echo "$screenwidth"/2-"$windowwidth"/2 | bc)
windowy=$(echo "$screenheight"/2-"$windowheight"/2 | bc)

case "$class" in
  Thunar )
    case "$(xprop -id "$wid" _NET_WM_WINDOW_TYPE)" in
      *_NET_WM_WINDOW_TYPE_NORMAL* )
        echo state=pseudo_tiled rectangle="$windowwidth"x"$windowheight"+"$windowx"+"$windowy";;
    esac;;
  Nitrogen | zoom )
    case "$(xprop -id "$wid" _NET_WM_WINDOW_TYPE)" in
      *_NET_WM_WINDOW_TYPE_NORMAL* )
        echo state=pseudo_tiled;;
    esac;;
esac
