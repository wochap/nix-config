{ config, ... }:

let userName = config._userName;
in {
  imports = [
    # HACK: it needs to load first
    ./mixins/overlays.nix

    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/default-browser
    ./mixins/pkgs-gtk.nix
    ./mixins/pkgs-linux.nix
    ./mixins/pkgs-node.nix
    ./mixins/pkgs-python
    ./mixins/pkgs-qt.nix
    ./mixins/pkgs.nix
    ./mixins/secrets.nix
    ./mixins/temp-sensor.nix
  ];

  config = {
    home-manager.users.${userName} = { imports = [ ./modules/symlinks.nix ]; };
  };
}
