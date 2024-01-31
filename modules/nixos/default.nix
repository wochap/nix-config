{ ... }:

{
  imports = [
    ./nixos/pkgs-python
    ./nixos/nix-common.nix
    ./nixos/nixos.nix
    ./nixos/pkgs-gtk.nix
    ./nixos/pkgs-linux.nix
    ./nixos/pkgs-node.nix
    ./nixos/pkgs-qt.nix
    ./nixos/pkgs.nix
    ./nixos/secrets.nix
    ./nixos/temp-sensor.nix

    ./de/dwl
    ./de/gnome
    ./de/hyprland
    ./de/kde
    ./de/river
    ./de/sway
    ./de/wayland-wm/dunst
    ./de/wayland-wm/gammastep
    ./de/wayland-wm/kanshi
    ./de/wayland-wm/swappy
    ./de/wayland-wm/swww
    ./de/wayland-wm/system
    ./de/wayland-wm/tofi
    ./de/wayland-wm/waybar
    ./de/wayland-wm/wayland-wm
    ./de/wayland-wm/wob
    ./de/wm/audio
    ./de/wm/backlight
    ./de/wm/bluetooth
    ./de/wm/calendar
    ./de/wm/cursor
    ./de/wm/dbus
    ./de/wm/email
    ./de/wm/fonts
    ./de/wm/greetd
    ./de/wm/gtk
    ./de/wm/music
    ./de/wm/neofetch
    ./de/wm/networking
    ./de/wm/plymouth
    ./de/wm/power-management
    ./de/wm/qt
    ./de/wm/xdg

    ./globals
    ./home

    ./programs/cli/nix-alien
    ./programs/cli/nix-direnv
    ./programs/gui/imv
    ./programs/gui/mongodb
    ./programs/gui/thunar
    ./programs/gui/zathura
    ./programs/tui/fontpreview-kik

    ./security/gnome-keyring
    ./security/gpg
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
  ];
}
