{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
  commonConfig = builtins.readFile ./dotfiles/kitty-common.conf;
  macosConfig = builtins.readFile ./dotfiles/kitty-macos.conf;
  linuxConfig = builtins.readFile ./dotfiles/kitty-linux.conf;
in
{
  config = {
    environment = {
      etc = {
        "kitty-session-tripper.conf".source = ./dotfiles/kitty-session-tripper.conf;
        "kitty-session-booker.conf".source = ./dotfiles/kitty-session-booker.conf;
        "kitty-session-nix-config.conf".source = ./dotfiles/kitty-session-nix-config.conf;
      };
    };
    home-manager.users.gean = {
      home.sessionVariables = {
        # TODO: test on darwin ⬇
        TERMINAL = "kitty";
      };

      home.file = {
        ".config/kitty/kitty.conf".text = ''
          ${if isDarwin then macosConfig else linuxConfig}
          ${commonConfig}
        '';
      };
    };
  };
}
