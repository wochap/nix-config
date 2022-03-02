{ config, pkgs, lib, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; lib = lib; };
in
{
  imports = [
    ./mixins/docker.nix # Comment on first install
    ./mixins/gnome-minimal-wm # Comment on first install
    ./mixins/gnome-pkgs.nix # Comment on first install
    ./mixins/lightdm
    ./mixins/lorri
    ./mixins/mongodb.nix
    ./mixins/nix-common.nix
    ./mixins/nixos-networking.nix
    ./mixins/nixos-shared
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs-xorg.nix
    ./mixins/pkgs.nix
    ./mixins/qt-pkgs.nix # Comment on first install
    # ./mixins/virt.nix
    ./mixins/vscode.nix
    ./mixins/xfce-minimal-wm.nix
    ./users/user-xorg.nix
    # ./mixins/ipwebcam
  ];

  config = {
    _displayServer = "xorg";

    environment = {
      etc = {
        "scripts/fix_caps_lock_delay.sh" = {
          source = ./scripts/fix_caps_lock_delay.sh;
          mode = "0755";
        };

        # Install script for recording
        "scripts/scrrec.sh" = {
          source = ./scripts/scrrec.sh;
          mode = "0755";
        };
      };
    };
  };
}
