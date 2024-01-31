{ config, lib, ... }:

let cfg = config._custom.cli.gpg;
in {
  options._custom.cli.gpg = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {

    _custom.hm = {

      programs.gpg.enable = true;
    };

  };
}
