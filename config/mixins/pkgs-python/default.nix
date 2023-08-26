{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";

  packageOverrides = pkgs.prevstable-python.callPackage ./python-packages.nix {
    pkgs = pkgs.prevstable-python;
  };
  python =
    pkgs.prevstable-python.python39.override { inherit packageOverrides; };
in {
  config = {
    environment.systemPackages = with pkgs;
      [
        (python.withPackages (ps:
          with ps;
          [
            animdl

            # required by 
            # config/users/mixins/email/scripts/icalview.py
            html2text
            pytz
            icalendar

            # required by mutt-display-filer.py
            # NOTE: no longer required
            pytz
            dateutil
          ] ++ (lib.optionals (!isDarwin) (with ps; [ pulsectl ]))))
      ];
  };
}
