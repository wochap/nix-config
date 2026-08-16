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

  calendarActive = calendarCfg.enable && calendarCfg.accounts != { };

  inherit (config._custom.globals) userName;
in
{
  config = lib.mkIf (cfg.enable && cfg.accounts != { }) {
    _custom.hm = {
      programs.khard = {
        enable = true;
        settings.general = {
          default_action = "list";
          editor = [ "nvim" ];
        };
      };

      accounts.contact.accounts = lib.mapAttrs' (
        _: acc:
        lib.nameValuePair acc.name {
          khard = {
            enable = true;
            type = "discover";
          };

          # khal needs a concrete collection, not a vdirsyncer discovery directive.
          khal = lib.mkIf calendarActive {
            enable = acc.khalBirthdays;
            collections = [ acc.localCollection ];
          };
        }
      ) cfg.accounts;

    };
  };
}
