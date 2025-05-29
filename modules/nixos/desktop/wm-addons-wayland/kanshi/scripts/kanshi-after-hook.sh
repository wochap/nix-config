#!/usr/bin/env bash

# restart ags
systemctl --user restart ags.service &

# restart wallpapaer
systemctl --user restart swww-daemon.service &
