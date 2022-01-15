{ config, pkgs, lib, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; lib = lib; };
in
{
  imports = [
    ./mixins/xfce-minimal-wm
    ./mixins/lightdm
    ./mixins/pkgs-xorg.nix
    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/fonts.nix
    # ./mixins/ipwebcam
    ./mixins/nixos-networking.nix
    ./mixins/keychron.nix
    ./mixins/gnome-pkgs.nix # Comment on first install
    ./mixins/gnome-minimal-wm # Comment on first install
    ./mixins/kde-pkgs.nix # Comment on first install
    ./mixins/docker.nix # Comment on first install
    ./mixins/lorri
    ./mixins/vscode.nix
    ./mixins/mongodb.nix
    ./users/user-xorg.nix
  ];

  config = {
    _displayServer = "xorg";

    environment = {
      etc = {
        "scripts/fix_caps_lock_delay.sh" = {
          source = ./scripts/fix_caps_lock_delay.sh;
          mode = "0755";
        };

        # Install script for screenshoot
        "scripts/scrcap.sh" = {
          source = ./scripts/scrcap.sh;
          mode = "0755";
        };

        # Install script for recording
        "scripts/scrrec.sh" = {
          source = ./scripts/scrrec.sh;
          mode = "0755";
        };

        "scripts/random-bg.sh" = {
          source = ./scripts/random-bg.sh;
          mode = "0755";
        };

        "scripts/start-neorg.sh" = {
          source = ./scripts/start-neorg.sh;
          mode = "0755";
        };
      };
    };

    # Add wifi tray
    programs.nm-applet.enable = true;
  };
}
