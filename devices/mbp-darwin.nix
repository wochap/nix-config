# Common configuration
{ config, pkgs, ... }:

let
  hostName = "gmbp";
in
{
  imports = [
    ./config/darwin.nix
  ];
}
