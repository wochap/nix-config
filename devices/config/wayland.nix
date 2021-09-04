{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/gnome-de.nix
    # ./mixins/sway
    # ./mixins/waybar
    # ./mixins/wayland-tiling.nix
    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/fonts.nix
    ./mixins/ipwebcam
    ./mixins/nixos-networking.nix
    ./mixins/keychron.nix
    ./mixins/default-browser
    ./mixins/apps-gnome # Comment on first install
    ./mixins/apps-kde.nix # Comment on first install
    ./mixins/apps-xfce.nix # Comment on first install
    ./mixins/docker.nix # Comment on first install
    ./mixins/lorri.nix
    ./mixins/vscode.nix
    ./users/user-wayland.nix
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
          enable = true;
          nvidiaWayland = true;
          wayland = true;
        };
      };
    };
  };
}
