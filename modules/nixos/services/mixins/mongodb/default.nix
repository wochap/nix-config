{ config, pkgs, lib, ... }:

let cfg = config._custom.services.mongodb;
in {
  options._custom.services.mongodb = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        robo3t = prev.runCommandNoCC "robo3t" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.robo3t}/bin/robo3t $out/bin/robo3t \
            --set "QT_QPA_PLATFORM" "xcb" \
            --set "QT_FONT_DPI" "${
              toString (if config._custom.hyprland.enable then 192 else 96)
            }"

          ln -sf ${prev.robo3t}/share $out/share
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      mongodb-compass
      mongodb-tools
      robo3t
      _custom.customNodePackages."migrate-mongo-9.0.0"
    ];
  };
}
