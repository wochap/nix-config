{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {

      programs.starship = {
        enable = true;
        settings = {
          add_newline = false;
          # character = {
          #   success_symbol = "[➜](bold green)";
          #   error_symbol = "[➜](bold red)";
          # };
          nix_shell = { disabled = true; };
          package = { disabled = true; };

          # Dracula theme
          aws.style = "bold #ffb86c";
          cmd_duration.style = "bold #f1fa8c";
          directory.style = "bold #50fa7b";
          hostname.style = "bold #ff5555";
          git_branch.style = "bold #ff79c6";
          git_status.style = "bold #ff5555";
          username = {
            format = "[$user]($style) on ";
            style_user = "bold #bd93f9";
          };
          character = {
            success_symbol = "[❯](bold #f8f8f2)";
            error_symbol = "[❯](bold #ff5555)";
          };
        };
      };
    };
  };
}
