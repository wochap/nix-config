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
    copyq # clipboard manager
    xfce.thunar # file manager

    # Dev tools
    gitAndTools.gh

    # Apps
    firefox
    pantheon.elementary-icon-theme
    vscode
    nix-prefetch-git
  ];

  home.sessionVariables = {
    # EDITOR = "nvim";
  };
}
