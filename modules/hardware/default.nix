{ config, pkgs, lib, ... }:

{
  imports = [ ./mixins/amd-cpu.nix ./mixins/amd-gpu.nix ];
}
