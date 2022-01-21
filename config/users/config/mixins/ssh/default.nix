{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment = { systemPackages = with pkgs; [ ]; };

    # Remember private keys?
    programs.ssh.startAgent = true;
    # programs.ssh.askPassword = "";

    users.users.${userName} = {
      # TODO: use keychain?
      openssh.authorizedKeys.keyFiles =
        [ "~/.ssh/id_rsa.pub" "~/.ssh/id_rsa_boc.pub" ];
    };

    home-manager.users.${userName} = {
      home.file = { ".ssh/config".source = ./dotfiles/ssh-config; };
    };
  };
}

