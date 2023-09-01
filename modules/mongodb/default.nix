{ config, pkgs, lib, ... }:

let cfg = config._custom.mongodb;
in {
  options._custom.mongodb = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        robo3t = prev.runCommandNoCC "robo3t" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.robo3t}/bin/robo3t $out/bin/robo3t \
            --set "QT_QPA_PLATFORM" "xcb" \
            --set "QT_FONT_DPI" "${
              if config._custom.hyprland.enable then 192 else 96
            }"

          ln -sf ${prev.robo3t}/share $out/share
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      mongodb-compass
      mongodb-tools
      robo3t
    ];

    services.mongodb = {
      enable = true;

      # custom mongodb versions took 18m to build
      package = pkgs.prevstable-mongodb.mongodb-4_2;

      # HACK: update the following values
      # if changing mongodb version gives errors
      pidFile = "/run/mongodb_nani4.pid";
      dbpath = "/var/db/mongodb_nani4";
    };
  };
}
