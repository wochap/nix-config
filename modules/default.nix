{ config, pkgs, lib, ... }:

{
  imports = [
    ./amd-cpu.nix
    ./amd-gpu.nix
    ./efi.nix
    ./flatpak
    ./globals.nix
    ./greetd
    ./hyprland
    ./river
    ./sway
    ./waydroid
    ./wayland-wm
  ];
}
