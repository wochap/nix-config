{ config, pkgs, lib, ... }:

{
  imports = [
    ./amd-cpu.nix
    ./amd-gpu.nix
    ./bspwm
    ./efi.nix
    ./globals.nix
    ./lightdm
    # ./river
    ./startx
    ./sway
    ./wayland-wm
    ./xorg-wm
  ];
}
