{ config, lib, ... }:

let cfg = config._custom.desktop.email;
in {
  imports = [
    ./mixins/accounts
    ./mixins/mailcap
    ./mixins/mailnotify.nix
    ./mixins/mbsync.nix
    ./mixins/neomutt.nix
    ./mixins/offlinemsmtp
  ];

  options._custom.desktop.email.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      services.imapnotify.enable = true;
      programs.msmtp.enable = true;
    };
  };
}
