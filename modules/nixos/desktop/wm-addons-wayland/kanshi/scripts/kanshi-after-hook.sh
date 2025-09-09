#!/usr/bin/env bash

# restart ags
# systemctl --user restart ags.service &

# restart wallpaper
systemctl --user restart swww-daemon.service &
