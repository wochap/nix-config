{ config, pkgs, lib, ... }:

let
  cfg = config._custom.cli.buku;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  buku-fzf = pkgs.writeTextFile {
    name = "buku-fzf";
    destination = "/bin/buku-fzf";
    executable = true;
    text = builtins.readFile ./scripts/buku-fzf.sh;
  };
in {
  options._custom.cli.buku = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
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
