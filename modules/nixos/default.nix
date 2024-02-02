{ ... }:

{
  imports = [
    ./de/dm/gdm
    ./de/dm/greetd
    ./de/gnome
    ./de/kde
    ./de/wm/dwl
    ./de/wm/hyprland
    ./de/wm/river
    ./de/wm/sway
    ./de/wm-addons/audio
    ./de/wm-addons/backlight
    ./de/wm-addons/bluetooth
    ./de/wm-addons/calendar
    ./de/wm-addons/cursor
    ./de/wm-addons/dbus
    ./de/wm-addons/email
    ./de/wm-addons/fonts
    ./de/wm-addons/gtk
    ./de/wm-addons/logind
    ./de/wm-addons/music
    ./de/wm-addons/neofetch
    ./de/wm-addons/networking
    ./de/wm-addons/plymouth
    ./de/wm-addons/power-management
    ./de/wm-addons/qt
    ./de/wm-addons/xdg
    ./de/wm-addons-wayland/cliphist
    ./de/wm-addons-wayland/dunst
    ./de/wm-addons-wayland/gammastep
    ./de/wm-addons-wayland/kanshi
    ./de/wm-addons-wayland/swayidle
    ./de/wm-addons-wayland/swaylock
    ./de/wm-addons-wayland/swww
    ./de/wm-addons-wayland/tofi
    ./de/wm-addons-wayland/utils
    ./de/wm-addons-wayland/waybar
    ./de/wm-addons-wayland/wayland-session
    ./de/wm-addons-wayland/wob

    ./globals

    ./programs/cli/nix-alien
    ./programs/cli/nix-direnv
    ./programs/gui/gtk
    ./programs/gui/imv
    ./programs/gui/mongodb
    ./programs/gui/qt
    ./programs/gui/thunar
    ./programs/gui/zathura
    ./programs/suites-linux
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
    ./services/steam
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
