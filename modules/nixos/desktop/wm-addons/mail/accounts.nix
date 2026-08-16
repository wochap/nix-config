{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};

  mkSignatureScript =
    signatureLines:
    pkgs.writeScript "signature" # python
      ''
        #!/usr/bin/env python
        lines = [
          ${lib.concatMapStringsSep ", " (
            l: "[${lib.concatMapStringsSep ", " (i: ''"${i}"'') l}]"
          ) signatureLines}
        ];
        print('\n'.join('{:32}{}'.format(*x) for x in lines))
      '';
in
{
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      accounts.email.maildirBasePath = "${hmConfig.home.homeDirectory}/Mail";

      accounts.email.accounts = lib.mapAttrs (name: acc: {
        address = acc.address;
        userName = acc.address;
        realName = lib.mkDefault "Gean Marroquin";
        flavor = acc.flavor;
        primary = acc.primary;

        passwordCommand = "${pkgs.coreutils}/bin/cat ${acc.passwordSecret.path}";

        msmtp.enable = true;
        imap.host = lib.mkIf (acc.imapHost != null) (lib.mkForce acc.imapHost);
        smtp = {
          host = lib.mkIf (acc.smtpHost != null) (lib.mkForce acc.smtpHost);
          port = 587;
          tls.useStartTls = true;
        };

        gpg = {
          key = acc.pgpKey;
          signByDefault = true;
          encryptByDefault = true;
        };

        signature = lib.mkIf (acc.signatureLines != [ ]) {
          showSignature = "append";
          command = mkSignatureScript acc.signatureLines;
        };

        folders = {
          inbox = lib.mkForce (if acc.sync == "lieer" then "mail" else "INBOX");
          drafts = lib.mkForce (if acc.sync == "lieer" then "mail/drafts" else "Drafts");
          sent = lib.mkForce (if acc.sync == "lieer" then "mail/sent" else "Sent");
          trash = lib.mkForce (if acc.sync == "lieer" then "mail/trash" else "Trash");
        };

      }) cfg.accounts;
    };
  };
}
