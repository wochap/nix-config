{ config, pkgs, lib, ... }:

let
  kmonad-repo = builtins.fetchGit {
    url = "https://github.com/kmonad/kmonad.git";
    rev = "159da000830e76e045420bd46f95643ce27f6f44";
    ref = "master";
  };
in
{
  imports = [
    (import "${kmonad-repo}/nix/nixos-module.nix")
  ];

  config = {
    services.kmonad = {
      enable = true;
      configfiles = [ ./main.kbd ];
    };
  };
}
