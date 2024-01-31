# common nixos and nix-darwin configuraion
{ config, pkgs, lib, inputs, ... }:

let inherit (config._custom.globals) userName homeDirectory;
in {
  config = {
    # Links those paths from derivations to /run/current-system/sw
    environment.pathsToLink = [ "/share" "/libexec" ];
  };
}
