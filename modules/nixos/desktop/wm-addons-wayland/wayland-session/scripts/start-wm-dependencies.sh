#!/usr/bin/env bash

dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP QT_QPA_PLATFORMTHEME
systemctl --user stop wayland-session.target
systemctl --user start wayland-session.target

is_failed=$(systemctl --user is-failed xdg-desktop-portal-gtk)
if [[ "$is_failed" == "failed" ]]; then
  systemctl --user restart xdg-desktop-portal-gtk
fi
