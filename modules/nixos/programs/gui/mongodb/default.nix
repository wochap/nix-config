{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.mongodb;
in {
  options._custom.programs.mongodb.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        robo3t = prev.runCommandNoCC "robo3t" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.robo3t}/bin/robo3t $out/bin/robo3t \
            --set "QT_QPA_PLATFORM" "xcb" \
            --set "QT_FONT_DPI" "${
              toString
              (if config._custom.desktop.hyprland.enable then 192 else 96)
            }"

          ln -sf ${prev.robo3t}/share $out/share
        '';

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
      robo3t
      _custom.nodePackages."migrate-mongo-9.0.0"

      redisinsight

      # PostgreSQL
      dbeaver-bin
    ];
  };
}
