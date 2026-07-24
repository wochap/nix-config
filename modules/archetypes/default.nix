{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./de-wayland-desktop.nix
    ./gnome.nix
    ./kde.nix
    ./sandbox.nix
    ./server.nix
    ./wm-wayland-desktop.nix
  ];
}
