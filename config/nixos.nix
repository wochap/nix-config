{ config, pkgs, lib, ... }:

{
  imports = [
    ./users/user-nixos.nix

    ./mixins/cht
    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs-gtk.nix
    ./mixins/pkgs-linux.nix
    ./mixins/pkgs-node.nix
    ./mixins/pkgs-python
    ./mixins/pkgs-qt.nix
    ./mixins/pkgs.nix
    ./mixins/temp-sensor.nix
    ./mixins/vscode.nix
  ];
}
