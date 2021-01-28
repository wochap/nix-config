# Common configuration
{ config, pkgs, ... }:

{
  # Generates ~/.gitconfig
  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = "wochap";
    userEmail = "gean.marroquin@gmail.com";
    aliases = {
      co = "checkout";
      ci = "commit";
      st = "status";
    };
    extraConfig = {
      core.editor = "vim";
      pull.rebase = "false";
    };
  };
}
