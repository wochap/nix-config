{ config, pkgs, lib, ... }:

let cfg = config._custom.cli.asciinema;
in {
  options._custom.cli.asciinema.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = with pkgs; [
          asciinema # record terminal
          asciinema-agg # generate GIF
          asciinema-scenario # generate recording from txt files
        ];
      };
    };
  };
}

