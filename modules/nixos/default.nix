{ ... }:

{
  imports = [
    ./desktop/display-managers/gdm
    ./desktop/display-managers/greetd

    ./desktop/desktop-managers/gnome
    ./desktop/desktop-managers/kde

    ./desktop/window-managers/dwl
    ./desktop/window-managers/hyprland
    ./desktop/window-managers/labwc
    ./desktop/window-managers/openbox

    ./desktop/wm-addons/audio
    ./desktop/wm-addons/backlight
    ./desktop/wm-addons/bluetooth
    ./desktop/wm-addons/calendar
    ./desktop/wm-addons/cursor
    ./desktop/wm-addons/dbus
    ./desktop/wm-addons/email
    ./desktop/wm-addons/fonts
    ./desktop/wm-addons/gtk
    ./desktop/wm-addons/logind
    ./desktop/wm-addons/music
    ./desktop/wm-addons/neofetch
    ./desktop/wm-addons/networking
    ./desktop/wm-addons/plymouth
    ./desktop/wm-addons/power-management
    ./desktop/wm-addons/qt
    ./desktop/wm-addons/udev-rules
    ./desktop/wm-addons/xdg
    ./desktop/wm-addons/xwaylandvideobridge

    ./desktop/wm-addons-wayland/ags
    ./desktop/wm-addons-wayland/cliphist
    ./desktop/wm-addons-wayland/dunst
    ./desktop/wm-addons-wayland/electron-support
    ./desktop/wm-addons-wayland/gammastep
    ./desktop/wm-addons-wayland/kanshi
    ./desktop/wm-addons-wayland/sfwbar
    ./desktop/wm-addons-wayland/swayidle
    ./desktop/wm-addons-wayland/swaylock
    ./desktop/wm-addons-wayland/swww
    ./desktop/wm-addons-wayland/tofi
    ./desktop/wm-addons-wayland/wayland-utils
    ./desktop/wm-addons-wayland/waybar
    ./desktop/wm-addons-wayland/sfwbar
    ./desktop/wm-addons-wayland/wayland-session
    ./desktop/wm-addons-wayland/ydotool

    ./desktop/wm-addons-xorg/tint2
    ./desktop/wm-addons-xorg/xorg-session
    ./desktop/wm-addons-xorg/xorg-utils
    ./desktop/wm-addons-xorg/xsettingsd

    ./gaming/emulators
    ./gaming/steam
    ./gaming/utils

    ./globals

    ./programs/cli/nix-alien

    ./programs/gui/gtk
    ./programs/gui/imv
    ./programs/gui/mongodb
    ./programs/gui/qt
    ./programs/gui/thunar
    ./programs/gui/zathura

    ./programs/others-linux

    ./programs/tui/figlet
    ./programs/tui/fontpreview-kik

    ./security/doas
    ./security/gnome-keyring
    ./security/gpg
    ./security/polkit
    ./security/ssh

    ./services/android
    ./services/docker
    ./services/flatpak
    ./services/interception-tools
    ./services/ipwebcam
    ./services/llm
    ./services/syncthing
    ./services/virt
    ./services/waydroid

    ./system/boot
    ./system/others
    ./system/locale
    ./system/windows

    ./user
  ];
}
