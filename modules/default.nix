{ config, pkgs, lib, ... }:

{
  imports = [
    ./android
    ./docker
    ./dwl
    ./flatpak
    ./globals.nix
    ./gnome
    ./gui
    ./hardware
    ./hyprland
    ./interception-tools
    ./ipwebcam
    ./mbpfan
    ./mongodb
    ./river
    ./steam
    ./sway
    ./tui
    ./virt
    ./waydroid
    ./wayland-wm
    ./wm
  ];
}
