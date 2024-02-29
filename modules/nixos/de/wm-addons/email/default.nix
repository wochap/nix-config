{ config, lib, ... }:

let cfg = config._custom.de.email;
in {
  imports = [
    ./accounts
    ./mailcap.nix
    ./mailnotify.nix
    ./mbsync.nix
    ./neomutt.nix
    ./offlinemsmtp.nix
  ];

  options._custom.de.email.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      services.imapnotify.enable = true;
      programs.msmtp.enable = true;
    };
  };
}
