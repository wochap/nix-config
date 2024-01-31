{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.mangadesk;
  userName = config._userName;
in {
  options._custom.tui.mangadesk = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ _custom.mangadesk ];

      xdg.configFile = {
        "mangadesk/config.json".source = ./dotfiles/config.json;
      };
    };
  };
}
