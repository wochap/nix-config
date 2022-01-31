{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
in {
  config = {
    programs = if (!isDarwin) then {
      # Remember private keys?
      ssh.startAgent = true;

      # ssh.askPassword = "";
    } else {};

    users.users.${userName} = lib.mkIf (!isDarwin) {
      # TODO: use keychain?
      openssh.authorizedKeys.keyFiles =
        [ "~/.ssh/id_ed25519.pub" "~/.ssh/id_rsa.pub" "~/.ssh/id_rsa_boc.pub" ];
    };

    home-manager.users.${userName} = {
      home.file = { ".ssh/config".source = ./dotfiles/ssh-config; };
    };
  };
}

