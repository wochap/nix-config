{ config, pkgs, lib, ... }:

with lib;
let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};

  accountConfig = {
    address = "geanb@bandofcoders.com";
    name = "Work";
    color = "blue";
  };

  helper = import ./helper.nix { inherit config pkgs lib; };
in {
  config = {
    home-manager.users.${userName} = {

      accounts.email.accounts.Work = mkMerge [
        (helper.commonConfig accountConfig)
        (helper.imapnotifyConfig accountConfig)
        helper.gpgConfig
        {
          flavor = "gmail.com";
          folders = {
            drafts = "[Gmail]/Drafts";
            sent = "[Gmail]/Sent Mail";
            trash = "[Gmail]/Trash";
          };
        }
      ];
    };
  };
}
