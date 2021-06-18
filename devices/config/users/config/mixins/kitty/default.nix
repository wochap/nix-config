{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      etc = {
        "kitty-session-tripper.conf".source = ./dotfiles/kitty-session-tripper.conf;
        "kitty-session-booker.conf".source = ./dotfiles/kitty-session-booker.conf;
      };
    };
    home-manager.users.gean = {
      home.sessionVariables = {
        TERMINAL = "kitty";
      };

      home.file = {
        ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
      };
    };
  };
}
