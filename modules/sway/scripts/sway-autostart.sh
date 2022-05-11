#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop &
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop

# exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

kanshi &
# way-displays &

# clipboard
wl-copy " " &
clipman clear --all &
wl-paste --watch clipman store --primary &

/etc/scripts/import-gsettings.sh &
mako &
gammastep -O 4000 &
waybar &
blueberry-tray &
# light -S 20 &
brightnessctl set 20% &
/etc/scripts/random-bg.sh &
# /etc/scripts/restart_goa_daemon.sh &
