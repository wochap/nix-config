{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
  commonConfig = builtins.readFile ./dotfiles/kitty-common.conf;
  macosConfig = builtins.readFile ./dotfiles/kitty-macos.conf;
  linuxConfig = builtins.readFile ./dotfiles/kitty-linux.conf;
  userName = config._userName;
in
{
  config = {
    environment = {
      shellAliases = {
        # https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-when-sshing-into-a-different-computer
        sshk = "kitty +kitten ssh";
      };
      etc = {
        "config/kitty-session-tripper.conf".source = ./dotfiles/kitty-session-tripper.conf;
        "config/kitty-session-booker.conf".source = ./dotfiles/kitty-session-booker.conf;
        "config/kitty-session-cinefest.conf".source = ./dotfiles/kitty-session-cinefest.conf;
        "config/kitty-session-nix-config.conf".source = ./dotfiles/kitty-session-nix-config.conf;
      };
      systemPackages = with pkgs; [
        kitty # terminal
      ];
    };
    home-manager.users.${userName} = {
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

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
    };
  };
}