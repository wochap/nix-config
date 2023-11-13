{ config, ... }:

let userName = config._userName;
in {
  imports = [ ./mixins/default-browser ./mixins/secrets.nix ];

  config = {
    home-manager.users.${userName} = { imports = [ ./modules/symlinks.nix ]; };
  };
}
