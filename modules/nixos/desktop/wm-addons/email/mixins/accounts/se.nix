{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config._custom.desktop.email;
  helper = import ./helper.nix { inherit config pkgs lib; };
  accountConfig = {
    address = "gean.bonifacio@socialexplorer.com";
    name = "SE";
    color = "yellow";
    pgpKey = "00F9FB30";
    signatureLines = [ [ "GPG: 00F9FB30" ] ];
  };
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      accounts.email.accounts.SE = mkMerge [
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
