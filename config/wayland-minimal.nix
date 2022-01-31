{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/docker.nix # Comment on first install
    ./mixins/fonts.nix
    ./mixins/gnome-minimal-wm # Comment on first install
    ./mixins/gnome-pkgs.nix # Comment on first install
    ./mixins/lorri
    ./mixins/nix-common.nix
    ./mixins/nixos-networking.nix
    ./mixins/nixos-shared
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/qt-pkgs.nix # Comment on first install
    ./mixins/sway
    ./mixins/vscode.nix
    ./mixins/wayland-tiling.nix
    ./mixins/xfce-minimal-wm.nix
    ./users/user-wayland.nix
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
