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

    # DE
    nitrogen # wallpaper manager
    pywal # theme color generator

    # Dev tools
    gitAndTools.gh

    # Apps
    firefox
    pantheon.elementary-icon-theme
    vscode
    nix-prefetch-git
    mpv # video player
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    lxappearance
    docker-compose
    docker
    slack
    mysql-workbench
    brave
  ];

  home.sessionVariables = {
    # EDITOR = "nvim";
  };
}
