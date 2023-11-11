{ config, ... }:

let userName = config._userName;
in {
  imports = [
    ./mixins/default-browser
    ./mixins/nixos
    ./mixins/secrets.nix
    ./mixins/user-nix.nix
    ./mixins/user-nixos.nix
  ];

  config = {
    home-manager.users.${userName} = { imports = [ ./modules/symlinks.nix ]; };
  };
}
