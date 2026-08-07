{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.buku;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  buku-fzf = pkgs.writeScriptBin "buku-fzf" (builtins.readFile ./scripts/buku-fzf.sh);
in
{
  options._custom.programs.buku.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        buku = prev.buku.overrideAttrs (oldAttrs: {
          version = "v5.1.1+g${inputs.buku.shortRev or "dirty"}";
          src = inputs.buku;
        });
      })
    ];

    _custom.hm = {
      home = {
        packages = with pkgs; [
          buku
          buku-fzf
          sqlite
        ];

        symlinks = {
          "${hmConfig.xdg.dataHome}/buku/bookmarks.db" =
            "${hmConfig.home.homeDirectory}/Sync/.config/buku/bookmarks.db";
        };
      };
    };
  };
}
