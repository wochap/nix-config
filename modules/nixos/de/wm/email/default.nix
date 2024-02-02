{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.email;
  offlinemsmtp-toggle-mode = pkgs.writeTextFile {
    name = "offlinemsmtp-toggle-mode";
    destination = "/bin/offlinemsmtp-toggle-mode";
    executable = true;
    text = builtins.readFile ./scripts/offlinemsmtp-toggle-mode.sh;
  };
in {
  imports = [
    # ./contact-query.nix
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
      home.packages = with pkgs; [ offlinemsmtp-toggle-mode ];

      services.imapnotify.enable = true;
      programs.msmtp.enable = true;
    };
  };
}
