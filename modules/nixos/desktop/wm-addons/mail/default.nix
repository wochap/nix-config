{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;

  accountSubmodule = lib.types.submodule {
    options = {
      address = lib.mkOption { type = lib.types.str; };
      name = lib.mkOption { type = lib.types.str; };
      flavor = lib.mkOption { type = lib.types.str; default = "plain"; };
      primary = lib.mkOption { type = lib.types.bool; default = false; };
      sync = lib.mkOption { type = lib.types.enum [ "lieer" "mbsync" "none" ]; default = "none"; };
      color = lib.mkOption { type = lib.types.str; default = ""; };
      pgpKey = lib.mkOption { type = lib.types.str; default = ""; };
      signatureLines = lib.mkOption {
        type = lib.types.listOf (lib.types.listOf lib.types.str);
        default = [ ];
      };
      passwordCommand = lib.mkOption { type = lib.types.str; default = ""; };
    };
  };

  lieerNames = lib.attrNames (lib.filterAttrs (_: acc: acc.sync == "lieer") cfg.accounts);
  mbsyncNames = lib.attrNames (lib.filterAttrs (_: acc: acc.sync == "mbsync") cfg.accounts);
  syncUnits =
    (map (name: "lieer-${name}.service") lieerNames)
    ++ lib.optional (mbsyncNames != [ ]) "mbsync.service";

  email-sync = pkgs.writeScriptBin "email-sync" ''
    #!/usr/bin/env bash
    exec ${pkgs.systemd}/bin/systemctl --user start ${lib.concatStringsSep " " syncUnits} "$@"
  '';
in
{
  imports = [
    ./accounts.nix
    ./imapnotify.nix
    ./lieer.nix
    # ./mailcap
    # ./mailnotify.nix
    # ./mbsync.nix
    # ./neomutt.nix
    ./notmuch.nix
    # ./offlinemsmtp
  ];

  options._custom.desktop.mail = {
    enable = lib.mkEnableOption "Mail setup";
    accounts = lib.mkOption {
      type = lib.types.attrsOf accountSubmodule;
      default = { };
      description = "Mail accounts configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = lib.mkIf (syncUnits != [ ]) [ email-sync ];
      programs.msmtp.enable = true;
    };
  };
}
