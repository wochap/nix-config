{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home.file = {
        ".ssh/config".source = ../../../../secrets/dotfiles/ssh-config;
      };

      # Remember passphrase of ssh keys across reboots
      # i'm in danger ewe
      programs.keychain = {
        enable = true;
        enableXsessionIntegration = true;
        enableBashIntegration = true;
        agents = [ "ssh" "gpg" ];
        keys = [ "id_ed25519" "id_rsa" "id_rsa_boc" "id_ed25519_boc" ];
      };
    };
  };
}
