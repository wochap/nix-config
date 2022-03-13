{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      # NOTE: ssh agent managed by gnome-keyring

      home.packages = with pkgs; [ sshfs ];

      home.file = {
        ".ssh/config".source = ../../../../secrets/dotfiles/ssh-config;
      };
    };
  };
}
