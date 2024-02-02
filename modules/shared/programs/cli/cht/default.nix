{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.cht;
  cht = pkgs.writeScriptBin "cht" (builtins.readFile ./scripts/cht.sh);
in {
  options._custom.programs.cht.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = [ cht ];
      xdg.configFile."cht/cht-languages.txt".source =
        ./dotfiles/cht-languages.txt;
      xdg.configFile."cht/cht-commands.txt".source =
        ./dotfiles/cht-commands.txt;
    };
  };
}
