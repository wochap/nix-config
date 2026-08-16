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

  # Same calendar-active predicate as the shared vdirsyncer module: khal
  # birthdays need the calendar module's khal
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
      # (see the shared wm-addons/vdirsyncer.nix)
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
            # Discover all concrete collections below the account's local
            # vdirsyncer root. Khard itself does not retain the parent account
            # name when it expands these directories.
            type = "discover";
          };

          # Birthdays use the same concrete collection. Never pass
          # vdirsyncer's `from a` / `from b` discovery directives here.
          khal = lib.mkIf calendarActive {
            enable = acc.khalBirthdays;
            collections = [ acc.localCollection ];
          };
        }
      ) cfg.accounts;

    };
  };
}
