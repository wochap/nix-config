{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../../../packages { pkgs = pkgs; };
  ptsh-repo = builtins.fetchGit {
    url = "https://github.com/jszczerbinsky/ptSh";
    rev = "737685cf64dcd00572d3997a6f2b514219156288";
    ref = "main";
  };
in
{
  config = {
    environment = {
      systemPackages = [
        localPkgs.ptsh
      ];
    };

    home-manager.users.gean = {
      home.file = {
        ".local/share/ptSh/logo.txt".source = "${ptsh-repo}/src/logo.txt";
        ".local/share/ptSh/LICENSE".source = "${ptsh-repo}/LICENSE";
        ".local/share/ptSh/version.txt".text = "Version: cloned from v0.2-alpha";
        ".local/share/ptSh/config".source = "${ptsh-repo}/src/config";
        ".config/ptSh/config".source = ./dotfiles/config;
      };
    };
  };
}
