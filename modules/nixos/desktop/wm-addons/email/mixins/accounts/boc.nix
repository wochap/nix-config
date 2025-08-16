{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config._custom.desktop.email;
  inherit (config._custom.globals) secrets;
  helper = import ./helper.nix { inherit config pkgs lib; };
  accountConfig = {
    address = secrets.boc.email;
    name = "BOC";
    color = "blue";
    pgpKey = "391E628A";
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
