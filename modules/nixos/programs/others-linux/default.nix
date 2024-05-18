{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.others-linux;
in {
  options._custom.programs.others-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        bruno = prev.runCommandNoCC "bruno" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.bruno}/bin/bruno $out/bin/bruno \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland"

          ln -sf ${prev.bruno}/share $out/share
        '';

        freetube = prev.runCommandNoCC "freetube" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.freetube}/bin/freetube $out/bin/freetube \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland"

          ln -sf ${prev.freetube}/share $out/share
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      # APPS
      dmenu # menu
      galaxy-buds-client
      # antimicroX # map kb/mouse to gamepad
      # mysql-workbench
      # skypeforlinux
      # teamviewer
      # zoom-us

      # ELECTRON APPS
      bitwarden
      brave
      bruno # like postman
      element-desktop-wayland
      freetube
      google-chrome
      microsoft-edge
      slack
    ];

    _custom.hm = {
      xdg.desktopEntries = {
        bruno = {
          name = "bruno";
          exec = "bruno %U";
        };
        freetube = {
          name = "Freetube";
          exec = "freetube %U";
        };
        figma = {
          name = "Figma";
          exec = "google-chrome-stable --app=https://www.figma.com";
        };
      };
    };
  };
}

