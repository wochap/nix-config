{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config._custom.desktop.email;
  helper = import ./helper.nix { inherit config pkgs lib; };
  accountConfig = {
    address = "gean.marroquin@gmail.com";
    name = "Personal";
    color = "red";
    pgpKey = "E73095E1";
    signatureLines = [
      [ "Gean Marroquin" "Software Engineer" ]
      [ "https://geanmar.com" ]
      [ "GPG: E73095E1" ]
    ];
  };
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
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
