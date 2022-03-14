{ config, pkgs, lib, inputs, ... }:

let localPkgs = import ../packages { inherit pkgs lib; };
in {
  config = {
    environment.systemPackages = with pkgs;
      [
        # global python
        (python3.withPackages (ps:
          with ps; [
            # required by volume.py
            pulsectl

            # required by icalview.py
            html2text
            pytz
            icalendar

            # required by mutt-display-filer.py
            pytz
            dateutil
          ]))
      ];
  };
}
