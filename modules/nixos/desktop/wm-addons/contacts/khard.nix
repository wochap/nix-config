{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.contacts;
  calendarCfg = config._custom.desktop.calendar;
  mailCfg = config._custom.desktop.mail;

  # same predicate as the vdirsyncer frequency ownership in
  # mixins/vdirsyncer.nix: khal birthdays need the calendar module's khal
  # setup; without it there is nothing to show birthdays in and the
  # per-account `khalBirthdays` option is a no-op.
  calendarActive = calendarCfg.enable && calendarCfg.accounts != { };

  inherit (config._custom.globals) userName;
in
{
  config = lib.mkIf (cfg.enable && cfg.accounts != { }) {
    _custom.hm = {
      # address book TUI reading the synced local vdirs; the
      # [[addressbooks]] sections come from accounts.contact.accounts
      # (see vdirsyncer.nix)
      programs.khard = {
        enable = true;
        settings.general = {
          default_action = "list";
          # khard edits vCards as plain text
          editor = [ "nvim" ];
        };
      };

      accounts.contact.accounts = lib.mapAttrs' (
        _: acc:
        lib.nameValuePair acc.name {
          khard = {
            enable = true;
            # the sync discovers one collection (subdirectory) per contact
            # list under localPath, so khard must discover the vdirs
            # instead of reading localPath as a single vdir
            type = "discover";
          };

          # contact birthdays in khal (home-manager generates a `birthdays`
          # calendar per account from the collections); no-op when the
          # calendar stack is absent. the collection names (subdirectories
          # of localPath) are only known after the first `vdirsyncer
          # discover`, and home-manager names the birthday calendar after
          # the contact account unless collections are given — which would
          # collide with and replace the same-named calendar account's
          # khal section. birthdays therefore stay off until `collections`
          # is set.
          khal = lib.mkIf calendarActive {
            enable = acc.khalBirthdays && acc.collections != null;
            inherit (acc) collections;
          };
        }
      ) cfg.accounts;


    };
  };
}
