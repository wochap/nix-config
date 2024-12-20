{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.lang-ruby;
in {
  options._custom.programs.lang-ruby.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      ruby
    ];
  };
}

