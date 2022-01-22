{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/lightdm
    ./mixins/docker.nix # Comment on first install
    ./mixins/fonts.nix
    ./mixins/gnome-minimal-wm # Comment on first install
    ./mixins/gnome-pkgs.nix # Comment on first install
    ./mixins/kde-pkgs.nix # Comment on first install
    ./mixins/keychron.nix
    ./mixins/lorri
    ./mixins/nix-common.nix
    ./mixins/nixos-networking.nix
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/vscode.nix
    ./mixins/wayland-tiling.nix
    # ./mixins/xfce-minimal-wm
    ./users/user-wayland.nix
    # ./mixins/sway
    # ./mixins/waybar
  ];

  config = {
    _displayServer = "wayland";

    # For legacy apps
    programs.xwayland.enable = true;

    environment = {
      sessionVariables = {
        # Force GTK to use wayland
        # doesn't work with nvidia?
        # GDK_BACKEND = "wayland";
        # CLUTTER_BACKEND = "wayland";

        # Force firefox to use wayland
        MOZ_ENABLE_WAYLAND = "1";
      };
    };

    services.xserver = {
      enable = true;
      displayManager = {
        gdm = {
          enable = false;
          # nvidiaWayland = true;
          wayland = true;
        };
      };
    };
  };
}
