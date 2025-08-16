{ config, pkgs, lib, ... }:

with lib;
let
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (pkgs._custom) offlinemsmtp;
  mkSignatureScript = signatureLines:
    pkgs.writeScript "signature" # python
    ''
      #!/usr/bin/env python
      lines = [
        ${
          concatMapStringsSep ", "
          (l: "[${concatMapStringsSep ", " (i: ''"${i}"'') l}]") signatureLines
        }
      ];
      print('\n'.join('{:32}{}'.format(*x) for x in lines))
    '';
in {
  commonConfig = { address, name, color, pgpKey ? "", ... }: {
    inherit address;

    realName = mkDefault "Gean Marroquin";
    userName = mkDefault address;
    passwordCommand = mkDefault
      "${pkgs.coreutils}/bin/cat ${hmConfig.xdg.configHome}/secrets/mail/${
        lib.toLower name
      }";

    mbsync = {
      enable = true;
      create = "both";
      remove = "both";
      expunge = "both";
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
        ''set pgp_default_key = "${pgpKey}"''
        ''set pgp_sign_as = "${pgpKey}"''
      ] ++ (optional (color != "") "color status ${color} default"));
    };

    folders.inbox = "INBOX";
  };

  gpgConfig.gpg = {
    encryptByDefault = true;
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
