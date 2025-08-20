{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.buku;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  buku-fzf =
    pkgs.writeScriptBin "buku-fzf" (builtins.readFile ./scripts/buku-fzf.sh);
in {
  options._custom.programs.buku.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        buku = prev.buku.overrideAttrs (oldAttrs: {
          src = prev.fetchFromGitHub {
            owner = "jarun";
            repo = "buku";
            rev = "641024baa68fa853bf53e593765ca9701a1e3ccb";
            sha256 = "sha256-PODFG9zBiyLOie1v0Anypxso6jMqVE2L/Vm/oQ/AEXI=";
          };
        });
      })
    ];

    _custom.hm = {
      home = {
        packages = with pkgs; [ buku buku-fzf sqlite ];

        symlinks = {
          "${hmConfig.xdg.dataHome}/buku/bookmarks.db" =
            "${hmConfig.home.homeDirectory}/Sync/.config/buku/bookmarks.db";
        };
      };
    };
  };
}

