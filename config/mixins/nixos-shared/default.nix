{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      etc = {
        "dotfiles/cht-languages.txt".source = ./dotfiles/cht-languages.txt;
        "dotfiles/cht-commands.txt".source = ./dotfiles/cht-commands.txt;

        "scripts/cht.sh" = {
          source = ./scripts/cht.sh;
          mode = "0755";
        };

        # TODO: remove
        "scripts/random-bg.sh" = {
          source = ./scripts/random-bg.sh;
          mode = "0755";
        };
        "scripts/system/random-bg.sh" = {
          source = ./scripts/random-bg.sh;
          mode = "0755";
        };
      };
    };
  };
}

