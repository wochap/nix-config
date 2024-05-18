{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.lang-ruby;
in {
  options._custom.dev.lang-ruby.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      ruby
      prevstable-rubymine.jetbrains.ruby-mine
    ];
  };
}

