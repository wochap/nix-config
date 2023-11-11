{ config, pkgs, lib, ... }:

let
  cht = pkgs.writeTextFile {
    name = "cht";
    destination = "/bin/cht";
    executable = true;
    text = builtins.readFile ./scripts/cht.sh;
  };
in {
  config = {
    environment = {
      systemPackages = [ cht ];
      etc = {
        "dotfiles/cht-languages.txt".source = ./dotfiles/cht-languages.txt;
        "dotfiles/cht-commands.txt".source = ./dotfiles/cht-commands.txt;
      };
    };
  };
}
