{ config, pkgs, lib, ... }:

{
  imports = [ ./amd-cpu.nix ./amd-gpu.nix ./globals.nix ];
}
