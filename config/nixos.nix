{ config, pkgs, lib, ... }:

{
  imports = [
    ./users/user-nixos.nix

    ./mixins/gnome-minimal-wm

    ./mixins/docker.nix
    ./mixins/gnome-pkgs.nix
    ./mixins/lorri
    ./mixins/mongodb.nix
    ./mixins/nix-common.nix
    ./mixins/nixos-networking.nix
    ./mixins/nixos-shared
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs-linux.nix
    ./mixins/pkgs-node.nix
    ./mixins/pkgs-python
    ./mixins/pkgs.nix
    ./mixins/qt-pkgs.nix
    ./mixins/virt.nix
    ./mixins/vscode.nix
    ./mixins/xfce-minimal-wm.nix
    # ./mixins/greetd.nix
    # ./mixins/ipwebcam
  ];
}
