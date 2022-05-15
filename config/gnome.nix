{ config, pkgs, lib, ... }:

{
  imports = [
    ./users/user-nixos.nix

    ./mixins/gnome-de.nix

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
    ./mixins/pkgs-python.nix
    ./mixins/pkgs.nix
    ./mixins/qt-pkgs.nix
    ./mixins/vscode.nix
    # ./mixins/ipwebcam
  ];

  config = {
    _displayServer = "wayland";

    # For legacy apps
    programs.xwayland.enable = true;

    services.xserver = {
      enable = true;
      displayManager = {
        gdm = {
          enable = true;
          nvidiaWayland = true;
          wayland = true;
        };
      };
    };
  };
}
