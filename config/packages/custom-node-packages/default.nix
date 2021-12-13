{ pkgs, nodejs, stdenv, fetchFromGitHub }:

let
  super = import ./composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  };
in super
