{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  imv = "${pkgs.imv}/bin/imv";
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
        image/jpg; ${imv} %s
        image/jpeg; ${imv} %s
        image/pjpeg; ${imv} %s
        image/png; ${imv} %s
        image/gif; ${imv} %s

        # iCal
        text/calendar; ${icalviewScript}; copiousoutput
        application/calendar; ${icalviewScript}; copiousoutput
        application/ics; ${icalviewScript}; copiousoutput
      '';
    };
  };
}
