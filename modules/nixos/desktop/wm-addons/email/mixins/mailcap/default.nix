{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.email;
  icalviewScript =
    pkgs.writeScript "icalview" (builtins.readFile ./icalview.py);
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ lynx catdoc ];

      xdg.configFile."neomutt/mailcap".text = ''
        # MS Word documents
        application/msword; catdoc %s; copiousoutput;
        application/vnd.ms-excel; xls2csv %s; copiousoutput;
        application/vnd.ms-powerpoint; catppt %s; copiousoutput;

        # HTML
        text/html; lynx -assume_charset=%{charset} -display_charset=utf-8 -dump %s; nametemplate=%s.html; copiousoutput

        # PDF documents
        application/pdf; zathura %s

        # Images
        image/jpg; imv %s
        image/jpeg; imv %s
        image/pjpeg; imv %s
        image/png; imv %s
        image/gif; imv %s

        # iCal
        text/calendar; ${icalviewScript}; copiousoutput
        application/calendar; ${icalviewScript}; copiousoutput
        application/ics; ${icalviewScript}; copiousoutput
      '';
    };
  };
}
