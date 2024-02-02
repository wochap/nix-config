{ config, pkgs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  options._custom.waylandWm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        showmethekey = prev.showmethekey.overrideAttrs (oldAttrs: {
          version = "6204cf1d4794578372c273348daa342589479b13";
          src = prev.fetchFromGitHub {
            owner = "AlynxZhou";
            repo = "showmethekey";
            rev = "6204cf1d4794578372c273348daa342589479b13";
            hash = "sha256-eeObomb4Gv/vpvViHsi3+O0JR/rYamrlZNZaXKL6KJw=";
          };
          buildInputs = oldAttrs.buildInputs ++ [ prev.libadwaita ];
        });
      })
    ];

    environment = {
      systemPackages = with pkgs; [
        wdisplays # control display outputs
        wlr-randr
        _custom.matcha
        showmethekey
        chayang # gradually dim the screen
        swaybg
      ];
    };
  };
}

