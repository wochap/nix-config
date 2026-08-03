{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config._custom.desktop.email;
  helper = import ./helper.nix { inherit config pkgs lib; };
  accountConfig = {
    address = "gean.marroquin@gmail.com";
    name = "Personal";
    sync = "lieer";
    color = "red";
    pgpKey = "E73095E1";
    signatureLines = [
      [
        "Gean Marroquin"
        "Software Engineer"
      ]
      [ "https://geanmar.com" ]
      [ "GPG: E73095E1" ]
    ];
  };
in
{
  config = lib.mkIf cfg.enable {
    _custom.desktop.email.accounts.${accountConfig.name} = accountConfig.sync;

    _custom.hm = {
      accounts.email.accounts.Personal = mkMerge [
        (helper.commonConfig accountConfig)
        (helper.syncConfig accountConfig)
        (helper.signatureConfig accountConfig)
        helper.gpgConfig
        {
          primary = true;
          flavor = "gmail.com";
        }
      ];
    };
  };
}
