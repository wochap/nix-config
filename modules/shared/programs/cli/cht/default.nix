{ config, pkgs, lib, ... }:

let
  cfg = config._custom.cli.cht;
  cht = pkgs.writeTextFile {
    name = "cht";
    destination = "/bin/cht";
    executable = true;
    text = builtins.readFile ./scripts/cht.sh;
  };
in {
  options._custom.cli.cht.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cht ];
      etc = {
        "dotfiles/cht-languages.txt".source = ./dotfiles/cht-languages.txt;
        "dotfiles/cht-commands.txt".source = ./dotfiles/cht-commands.txt;
      };
    };
  };
}
