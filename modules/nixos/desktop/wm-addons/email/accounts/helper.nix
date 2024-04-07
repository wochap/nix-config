{ config, pkgs, lib, ... }:

with lib;
let
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (pkgs._custom) offlinemsmtp;
  mkSignatureScript = signatureLines:
    pkgs.writeScript "signature" ''
      #!/usr/bin/env python

      ${concatMapStringsSep "\n" (l: ''print("${l}")'')
      (splitString "\n" signatureLines)}
    '';
in {
  # Common configuration
  commonConfig = { address, name, color ? "", ... }: {
    inherit address;

    realName = mkDefault "Gean Marroquin";
    userName = mkDefault address;
    passwordCommand = mkDefault
      "${pkgs.coreutils}/bin/cat ${hmConfig.xdg.configHome}/secrets/mail/${address}";

    mbsync = {
      enable = true;
      create = "both";
      remove = "both";
    };

    msmtp.enable = true;

    smtp = {
      port = 587;
      tls.useStartTls = true;
    };

    neomutt = {
      enable = true;
      sendMailCommand = "${offlinemsmtp}/bin/offlinemsmtp -a ${name}";

      extraConfig = concatStringsSep "\n" ([
        ''set folder="${hmConfig.accounts.email.maildirBasePath}"''
        ''set pgp_default_key = "E73095E1"''
      ] ++ (optional (color != "") "color status ${color} default"));
    };

    folders.inbox = "INBOX";
  };

  gpgConfig.gpg = {
    encryptByDefault = true;
    key = "0F36350551B61784AA2F1E2BFE4CF844E73095E1";
    signByDefault = true;
  };

  imapnotifyConfig = { name, ... }: {
    imapnotify = {
      enable = true;
      boxes = [ "INBOX" ];
      onNotify = "${pkgs.isync}/bin/mbsync ${name}:%s";
    };
  };

  signatureConfig = { signatureLines, ... }: {
    signature = {
      showSignature = "append";
      command = mkSignatureScript signatureLines;
    };
  };
}
