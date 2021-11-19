{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        trash-cli # required by vscode
        vscode
      ];

      sessionVariables = {
        # Fix vscode delete
        ELECTRON_TRASH="trash-cli";
      };
    };

    nixpkgs.overlays = [
      (final: prev: (
        (lib.optionalAttrs isWayland {
          vscode = (prev.runCommandNoCC "code"
            { buildInputs = with pkgs; [ makeWrapper ]; }
            ''
              makeWrapper ${prev.vscode}/bin/code $out/bin/code \
                --add-flags "--enable-features=UseOzonePlatform" \
                --add-flags "--ozone-platform=wayland"

              ln -sf ${prev.vscode}/share $out/share
            ''
          );
        })
      ))
    ];
  };
}
