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

