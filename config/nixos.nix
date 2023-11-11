{ ... }:

{
  imports = [
    # HACK: it needs to load first
    ./mixins/overlays.nix

    ./users/user-nixos.nix

    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/pkgs-gtk.nix
    ./mixins/pkgs-linux.nix
    ./mixins/pkgs-node.nix
    ./mixins/pkgs-python
    ./mixins/pkgs-qt.nix
    ./mixins/pkgs.nix
    ./mixins/temp-sensor.nix
  ];
}
