{ ... }:

{
  imports = [
    ./desktop/display-managers/gdm
    ./desktop/display-managers/greetd

    ./desktop/desktop-managers/gnome
    ./desktop/desktop-managers/kde

    ./desktop/window-managers/hyprland

    ./desktop/wm-addons/audio
    ./desktop/wm-addons/backlight
    ./desktop/wm-addons/bluetooth
    ./desktop/wm-addons/calendar
    ./desktop/wm-addons/cursor
    ./desktop/wm-addons/dbus
    ./desktop/wm-addons/email
    ./desktop/wm-addons/fastfetch
    ./desktop/wm-addons/fonts
    ./desktop/wm-addons/gtk
    ./desktop/wm-addons/logind
    ./desktop/wm-addons/mouseless
    ./desktop/wm-addons/music
    ./desktop/wm-addons/networking
    ./desktop/wm-addons/plymouth
    ./desktop/wm-addons/power-management
    ./desktop/wm-addons/qt
    ./desktop/wm-addons/udev-rules
    ./desktop/wm-addons/uwsm
    ./desktop/wm-addons/xdg

    ./desktop/wm-addons-wayland/ags
    ./desktop/wm-addons-wayland/cliphist
    ./desktop/wm-addons-wayland/electron-support
    ./desktop/wm-addons-wayland/gammastep
    ./desktop/wm-addons-wayland/hyprlock
    ./desktop/wm-addons-wayland/hyprsunset
    ./desktop/wm-addons-wayland/kanshi
    ./desktop/wm-addons-wayland/quickshell
    ./desktop/wm-addons-wayland/idle
    ./desktop/wm-addons-wayland/swww
    ./desktop/wm-addons-wayland/tofi
    ./desktop/wm-addons-wayland/wayland-utils
    ./desktop/wm-addons-wayland/wluma
    ./desktop/wm-addons-wayland/wayland-session
    ./desktop/wm-addons-wayland/xwaylandvideobridge
    ./desktop/wm-addons-wayland/ydotool

    ./gaming/chaotic
    ./gaming/emulators
    ./gaming/steam
    ./gaming/utils

    ./globals

    ./programs/cli/core-utils-extra-linux
    ./programs/cli/core-utils-linux

    ./programs/gui/dolphin
    ./programs/gui/electron
    ./programs/gui/gtk
    ./programs/gui/imv
    ./programs/gui/mongodb
    ./programs/gui/obs-studio
    ./programs/gui/qt
    ./programs/gui/thunar
    ./programs/gui/zathura

    ./programs/others-linux

    ./programs/tui/figlet
    ./programs/tui/fontpreview-kik

    ./security/doas
    ./security/gnome-keyring
    ./security/gpg
    ./security/kwallet
    ./security/network
    ./security/pam
    ./security/polkit
    ./security/ssh

    ./services/ai
    ./services/android
    ./services/docker
    ./services/flatpak
    ./services/interception-tools
    ./services/ipwebcam
    ./services/kdeconnect
    ./services/ms-intune
    ./services/syncthing
    ./services/virt
    ./services/waydroid

    ./system/apple
    ./system/boot
    ./system/console
    ./system/fhs-compat
    ./system/internationalization
    ./system/others
    ./system/windows

    ./user
  ];
}
