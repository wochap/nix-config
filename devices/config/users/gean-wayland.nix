{ config, pkgs, ... }:

{
  imports = [
    ./nix-common.nix
    ./nixos-common.nix
    ./config/wayland.nix
  ];

  config = {};
}
