{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.python;
  isDarwin = pkgs.stdenv.isDarwin;
  animdl = pkgs.prevstable-python.callPackage ./animdl.nix {
    pkgs = pkgs.prevstable-python;
  };
  python-remind = pkgs.prevstable-python.callPackage ./python-remind.nix {
    pkgs = pkgs.prevstable-python;
  };
  vidcutter = pkgs.prevstable-python.callPackage ./vidcutter.nix {
    pkgs = pkgs.prevstable-python;
  };
  packageOverrides = pkgs.prevstable-python.callPackage ./python-packages.nix {
    pkgs = pkgs.prevstable-python;
  };
  python =
    pkgs.prevstable-python.python311.override { inherit packageOverrides; };
  # python = inputs.nixpkgs-python.packages.${system}."3.9.16";
in {
  options._custom.programs.python.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # disable tests in some python packages?
    # source: https://discourse.nixos.org/t/force-nix-not-to-check-test-without-to-override-each-package/7616
    # nixpkgs.overlays = [
    #   (self: prev: rec {
    #     python311 = prev.python311.override {
    #       packageOverrides = self: prev: {
    #         hypothesis = prev.hypothesis.override { doCheck = false; };
    #         chardet = prev.chardet.overrideAttrs {
    #           doCheck = false;
    #           pythonImportsCheck = [ ];
    #           nativeCheckInputs = [ ];
    #         };
    #       };
    #     };
    #
    #     python311Packages = python311.pkgs;
    #   })
    # ];

    environment.systemPackages = with pkgs; [
      animdl
      python-remind
      vidcutter

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
