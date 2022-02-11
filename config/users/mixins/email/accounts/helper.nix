{ config, pkgs, lib, ... }:

with lib;
let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  localPkgs = import ../../../../packages {
    pkgs = pkgs;
    lib = lib;
  };

  offlinemsmtp = localPkgs.offlinemsmtp;

  # Create a signature script that gets a quote.
  mkSignatureScript = signatureLines:
    pkgs.writeScript "signature" ''
      #!${pkgs.python3}/bin/python
      import subprocess

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

    neomutt = {
      enable = true;
      sendMailCommand = "${offlinemsmtp}/bin/offlinemsmtp -a ${name}";

      extraConfig = concatStringsSep "\n" ([
        ''set folder="${hmConfig.accounts.email.maildirBasePath}"''

        # TODO: add default gpg pub key id
        # ''set pgp_default_key = "B50022FD"''
      ] ++ (optional (color != "") "color status ${color} default"));
    };

    folders.inbox = "INBOX";
  };

  gpgConfig.gpg = {
    encryptByDefault = true;
    key = "3F15C22BFD125095F9C072758904527AB50022FD";
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
    neomutt.extraConfig = ''
      set signature="${mkSignatureScript signatureLines}|"
    '';
  };
}
