{ ... }:

{
  imports = [
    # HACK: it needs to load first
    ./mixins/channels.nix

    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/pkgs-gtk.nix
    ./mixins/pkgs-linux.nix
    ./mixins/pkgs-node.nix
    ./mixins/pkgs-python
    ./mixins/pkgs-qt.nix
    ./mixins/pkgs.nix
    ./mixins/secrets.nix
    ./mixins/temp-sensor.nix
  ];
}
