#!/usr/bin/env bash

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

CM_LAUNCHER=rofi \
  clipmenu \
  -i \
  -p "" \
  -dpi "$DPI"
