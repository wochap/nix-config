{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/docker.nix # Comment on first install
    ./mixins/gnome-minimal-wm # Comment on first install
    ./mixins/gnome-pkgs.nix # Comment on first install
    ./mixins/lorri
    ./mixins/mongodb.nix
    ./mixins/nix-common.nix
    ./mixins/nixos-networking.nix
    ./mixins/nixos-shared
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs-linux.nix
    ./mixins/pkgs-node.nix
    ./mixins/pkgs-python.nix
    ./mixins/pkgs.nix
    ./mixins/qt-pkgs.nix # Comment on first install
    ./mixins/vscode.nix
    ./mixins/wayland-tiling.nix
    ./mixins/xfce-minimal-wm.nix
    ./users/user-wayland.nix
    # ./mixins/greetd.nix
    # ./mixins/ipwebcam
    # ./mixins/virt.nix
  ];

  config = {
    _displayServer = "wayland";

    # For legacy apps
    programs.xwayland.enable = true;

    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = false;
    };
  };
}
