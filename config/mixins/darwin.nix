{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Install home-manager
    (import "${inputs.home-manager-darwin}/nix-darwin")
  ];

  config = {};
}
