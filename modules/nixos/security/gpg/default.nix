{ config, lib, ... }:

let cfg = config._custom.security.gpg;
in {
  options._custom.security.gpg.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      # NOTE: gpg agent managed by gnome-keyring
      programs.gpg.enable = true;
    };
  };
}
