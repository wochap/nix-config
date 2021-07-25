{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/sway
    ./mixins/waybar
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
    ./users/gean-wayland.nix
  ];

  config = {
    _displayServer = "wayland";

    # For legacy apps
    programs.xwayland.enable = true;

    environment = {
      systemPackages = with pkgs; [
        # sway-alttab
        # brightnessctl
        mako # notification daemon
        # pactl # control a running PulseAudio sound server
        polkit_gnome
        swaylock
        swaylock # lockscreen
        wl-clipboard
      ];
      sessionVariables = {
        # Force GTK to use wayland
        GDK_BACKEND = "wayland";
        CLUTTER_BACKEND = "wayland";

        # Force firefox to use wayland
        MOZ_ENABLE_WAYLAND = "1";
      };
    };

    services.xserver = {
      enable = true;
      displayManager = {
        # gdm = {
        #   enable = true;
        #   nvidiaWayland = true;
        #   wayland = true;
        # };
        sddm = {
          enable = true;
          enableHidpi = true;
        };
      };
    };
  };
}
