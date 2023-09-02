{ config, pkgs, lib, ... }:

{
  imports = [
    ./android
    ./docker
    ./dwl
    ./flatpak
    ./globals.nix
    ./gui
    ./hardware
    ./hyprland
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
