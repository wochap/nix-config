{ config, pkgs, hostName ? "unknown", ... }:

{
  imports = [
    ./common.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "gean";
  home.homeDirectory = "/home/gean";

  # User packages
  home.packages = with pkgs; [
    # Basic tools
    htop
    wget
    radeontop # like htop for gpu
    scrot # screenshoot
    pamixer # control audio

    # DE
    nitrogen # wallpaper manager
    pywal # theme color generator
    volumeicon
    arc-theme
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    lxappearance

    # Dev tools
    gitAndTools.gh
    docker-compose
    docker
    mysql-workbench
    postman
    vscode

    # Apps
    firefox
    brave
    google-chrome
    pantheon.elementary-icon-theme
    nix-prefetch-git
    mpv # video player
    slack
  ];

  home.sessionVariables = {
    # EDITOR = "nvim";
  };
}
