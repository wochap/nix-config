{ config, pkgs, lib, ... }:

{
  imports = [
    ./amd-cpu.nix
    ./amd-gpu.nix
    ./bspwm
    ./globals.nix
    ./lightdm
    ./startx
    ./sway
    ./wayland-wm
    ./xorg-wm
  ];
}
