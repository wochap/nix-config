{ config, pkgs, lib, inputs, system, ... }:

let cfg = config._custom.programs.electron;
in {
  options._custom.programs.electron.enable = lib.mkEnableOption { };

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
      bitwarden
      bruno # like postman
      element-desktop
      freetube
      slack
      obsidian
      inputs.figma-linux.packages.${system}.default
    ];

    _custom.hm = {
      xdg.desktopEntries = {
        bruno = {
          name = "bruno";
          exec = "bruno %U";
        };
        figma-pwa = {
          name = "Figma PWA";
          exec =
            "google-chrome-stable --profile-directory=Default --app=https://www.figma.com";
        };
        freetube = {
          name = "Freetube";
          exec = "freetube %U";
        };
      };
    };
  };
}
