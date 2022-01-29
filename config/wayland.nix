{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/docker.nix # Comment on first install
    ./mixins/fonts.nix
    ./mixins/gnome-de.nix
    ./mixins/gnome-pkgs.nix # Comment on first install
    ./mixins/ipwebcam
    ./mixins/kde-pkgs.nix # Comment on first install
    # ./mixins/keychron.nix
    ./mixins/lorri
    ./mixins/nix-common.nix
    ./mixins/nixos-networking.nix
    ./mixins/nixos-shared
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/thunar.nix # Comment on first install
    ./mixins/vscode.nix
    ./users/user-wayland.nix
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
