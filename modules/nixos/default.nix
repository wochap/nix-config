{ ... }:

{
  imports = [
    ./nixos/pkgs-python
    ./nixos/pkgs-gtk.nix
    ./nixos/pkgs-linux.nix
    ./nixos/pkgs-node.nix
    ./nixos/pkgs-qt.nix
    ./nixos/pkgs.nix
    ./nixos/secrets.nix
    ./nixos/temp-sensor.nix

    ./de/dm/gdm
    ./de/dm/greetd
    ./de/dwl
    ./de/gnome
    ./de/hyprland
    ./de/kde
    ./de/river
    ./de/sway
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
    ./de/wm-wayland-addons/cliphist
    ./de/wm-wayland-addons/dunst
    ./de/wm-wayland-addons/gammastep
    ./de/wm-wayland-addons/kanshi
    ./de/wm-wayland-addons/swayidle
    ./de/wm-wayland-addons/swaylock
    ./de/wm-wayland-addons/swww
    ./de/wm-wayland-addons/tofi
    ./de/wm-wayland-addons/utils
    ./de/wm-wayland-addons/waybar
    ./de/wm-wayland-addons/wayland-session
    ./de/wm-wayland-addons/wob

    ./globals

    ./programs/cli/nix-alien
    ./programs/cli/nix-direnv
    ./programs/gui/imv
    ./programs/gui/mongodb
    ./programs/gui/thunar
    ./programs/gui/zathura
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
