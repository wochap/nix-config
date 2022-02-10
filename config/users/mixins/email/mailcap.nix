{ config, pkgs, lib, ... }:

let
  userName = config._userName;

  feh = "${pkgs.feh}/bin/feh";
  icalviewScript =
    pkgs.writeScript "icalview" (builtins.readFile ./scripts/icalview.py);
in {
  config = {
    home-manager.users.${userName} = {

      xdg.configFile."neomutt/mailcap".text = ''
        # HTML
        text/html; ${pkgs.elinks}/bin/elinks -dump %s; copiousoutput;

        # PDF documents
        application/pdf; ${pkgs.zathura}/bin/zathura %s

        # Images
        image/jpg; ${feh} %s
        image/jpeg; ${feh} %s
        image/pjpeg; ${feh} %s
        image/png; ${feh} %s
        image/gif; ${feh} %s

        # iCal
        text/calendar; ${icalviewScript}; copiousoutput
        application/calendar; ${icalviewScript}; copiousoutput
        application/ics; ${icalviewScript}; copiousoutput
      '';
    };
  };
}
