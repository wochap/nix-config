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

        "scripts/random-bg.sh" = {
          source = ./scripts/random-bg.sh;
          mode = "0755";
        };

        "scripts/start-neorg.sh" = {
          source = ./scripts/start-neorg.sh;
          mode = "0755";
        };
      };
    };

    # Add wifi tray
    programs.nm-applet.enable = true;
  };
}

