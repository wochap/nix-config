{ config, ... }:

let userName = config._userName;
in { config.home-manager.users.${userName}.imports = [ ./symlinks ]; }

