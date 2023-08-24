{ config, pkgs, lib, ... }:

with lib;
let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};

  accountConfig = {
    address = "gean.marroquin@gmail.com";
    name = "Personal";
    color = "red";
    signatureLines = ''
      Gean Marroquin
      Software Engineer

      https://geanmarroquin.com
    '';
  };

  helper = import ./helper.nix { inherit config pkgs lib; };
in {
  config = {
    home-manager.users.${userName} = {
      accounts.email.accounts.Personal = mkMerge [
        (helper.commonConfig accountConfig)
        (helper.imapnotifyConfig accountConfig)
        (helper.signatureConfig accountConfig)
        helper.gpgConfig
        {
          primary = true;
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
