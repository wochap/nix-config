{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.python;
  isDarwin = pkgs.stdenv.isDarwin;
  packageOverrides =
    pkgs.prevstable-python.callPackage ./pip2nix/python-packages.nix {
      pkgs = pkgs.prevstable-python;
    };
  python =
    pkgs.prevstable-python.python311.override { inherit packageOverrides; };
in {
  options._custom.programs.python.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      _custom.pythonPackages.animdl
      _custom.pythonPackages.python-remind
      _custom.pythonPackages.vidcutter

      pipx
      poetry
      pipenv
      (python.withPackages (ps:
        with ps;
        [
          pip

          # required by
          # config/users/mixins/email/scripts/icalview.py
          html2text
          pytz
          icalendar

          # required by mutt-display-filer.py
          # NOTE: no longer required
          # pytz
          # dateutil
        ] ++ (lib.optionals (!isDarwin) (with ps; [ pulsectl ]))))
    ];
  };
}
