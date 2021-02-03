{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    programs.qt5ct.enable = true;
    environment.systemPackages = with pkgs; [
      brightnessctl
      polkit_gnome

      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      lxappearance
    ];
    environment.pathsToLink = [ "/libexec" ];
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = with pkgs; [
        swaylock
        swayidle
        wl-clipboard
        mako # notification daemon
        alacritty # Alacritty is the default terminal in the config
        dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
      ];
    };
  };
}
