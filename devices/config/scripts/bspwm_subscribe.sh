#!/usr/bin/env bash

# Change border width of marked windows
while read -r line; do
	case "$line" in
		*'marked on')
      wid=$(echo $line | awk '{print $4}')
      bspc config -n "$wid" border_width 8
      # bspc config -n "$wid" normal_border_color \#f9826c
      # chwb -c 0xf9826c $wid
			;;
		*'marked off')
      wid=$(echo $line | awk '{print $4}')
			bspc config -n "$wid" border_width 2
      # bspc config -n "$wid" normal_border_color \#282e3a
      # chwb -c 0x282e3a $wid
			;;
	esac
done < <(bspc subscribe report node_flag)

# bspc node any.marked -g marked=off
