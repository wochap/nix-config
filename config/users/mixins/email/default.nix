{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  imports = [
    ./accounts
    # ./contact-query.nix
    ./mailcap.nix
    ./mailnotify.nix
    ./mbsync.nix
    ./neomutt.nix
    ./offlinemsmtp.nix
  ];

  config = {
    home-manager.users.${userName} = {

      services.imapnotify.enable = true;
      programs.msmtp.enable = true;
    };
  };
}
