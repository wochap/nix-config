{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  icalviewScript = pkgs.writeScript "icalview" (builtins.readFile ./icalview.py);
in
{
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        lynx
        catdoc
      ];

      xdg.configFile."neomutt/mailcap".text = ''
        # MS Word documents
        application/msword; catdoc %s; copiousoutput;
        application/vnd.ms-excel; xls2csv %s; copiousoutput;
        application/vnd.ms-powerpoint; catppt %s; copiousoutput;

        # HTML
        text/html; smart-open %s; nametemplate=%s.html
        text/html; lynx -assume_charset=%{charset} -display_charset=utf-8 -dump %s; nametemplate=%s.html; copiousoutput

        # PDF documents
        application/pdf; smart-open %s

        # Images
        image/jpg; smart-open %s
        image/jpeg; smart-open %s
        image/pjpeg; smart-open %s
        image/png; smart-open %s
        image/gif; smart-open %s

        # iCal
        text/calendar; ${icalviewScript}; copiousoutput
        application/calendar; ${icalviewScript}; copiousoutput
        application/ics; ${icalviewScript}; copiousoutput
      '';
    };
  };
}
