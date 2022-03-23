{ config, pkgs, lib, inputs, ... }:

let
  localPkgs = import ../packages { inherit pkgs lib; };
  isDarwin = config._displayServer == "darwin";
in {
  config = {
    environment.systemPackages = with pkgs;
      [
        # global python
        (python3.withPackages (ps:
          with ps;
          [
            # required by icalview.py
            html2text
            pytz
            icalendar

            # required by mutt-display-filer.py
            pytz
            dateutil
          ] ++ (lib.optionals (!isDarwin) (with ps; [ pulsectl ]))))
      ];
  };
}
