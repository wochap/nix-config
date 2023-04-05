{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";

  packageOverrides = pkgs.callPackage ./python-packages.nix { };
  python = pkgs.python39.override { inherit packageOverrides; };
in {
  config = {
    environment.systemPackages = with pkgs;
      [
        (python.withPackages (ps:
          with ps;
          [
            animdl

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
