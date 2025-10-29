{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.mongodb;
in {
  options._custom.programs.mongodb.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        mongodb-compass = prev.runCommandNoCC "mongodb-compass" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.mongodb-compass}/bin/mongodb-compass $out/bin/mongodb-compass \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--ignore-additional-command-line-flags"

          ln -sf ${prev.mongodb-compass}/share $out/share
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      mongodb-compass
      mongodb-tools
      _custom.nodePackages."migrate-mongo-9.0.0"

      redisinsight

      # PostgreSQL
      postgresql
      dbeaver-bin
    ];
  };
}
