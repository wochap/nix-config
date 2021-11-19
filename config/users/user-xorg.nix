{ config, pkgs, ... }:

{
  imports = [
    ./nix-common.nix
    ./nixos-common.nix
    ./config/xorg.nix
  ];

  config = {};
}
