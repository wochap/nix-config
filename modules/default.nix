{ config, pkgs, lib, ... }:

{
  imports = [
    ./amd-cpu.nix
    ./amd-gpu.nix
    ./bspwm
    ./efi.nix
    ./flatpak
    ./globals.nix
    ./greetd
    ./hyprland
    ./lightdm
    ./river
    ./startx
    ./sway
    ./waydroid
    ./wayland-wm
    ./xorg-wm
  ];
}
