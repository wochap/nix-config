{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config._custom.desktop.email;
  helper = import ./helper.nix { inherit config pkgs lib; };
  accountConfig = {
    address = "geanb@bandofcoders.com";
    name = "BOC";
    color = "blue";
  };
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {

      accounts.email.accounts.BOC = mkMerge [
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
