{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.email;
  offlinemsmtp-toggle-mode = pkgs.writeScriptBin "offlinemsmtp-toggle-mode"
    (builtins.readFile ./scripts/offlinemsmtp-toggle-mode.sh);
in {
  imports = [
    ./accounts
    ./mailcap.nix
    ./mailnotify.nix
    ./mbsync.nix
    ./neomutt.nix
    ./offlinemsmtp.nix
  ];

  options._custom.wm.email.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = [ offlinemsmtp-toggle-mode ];

      services.imapnotify.enable = true;
      programs.msmtp.enable = true;
    };
  };
}
