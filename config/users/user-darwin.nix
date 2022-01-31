{ config, lib, pkgs, ... }:

let
  userName = config._userName;
in
{
  imports = [
    ./nix-common.nix
    ./config/macos.nix
  ];

  config = {
    nix.gc.user = userName;
  };
}
