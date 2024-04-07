{ config, pkgs, lib, ... }:

let
  cfg = config._custom.dev.lang-python;
  packageOverrides =
    pkgs.prevstable-python.callPackage ./pip2nix/python-packages.nix {
      pkgs = pkgs.prevstable-python;
    };
  python =
    pkgs.prevstable-python.python311.override { inherit packageOverrides; };
in {
  options._custom.dev.lang-python.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pipx
      poetry
      pipenv
      (python.withPackages (ps:
        with ps;
        [
          pip
          # NOTE: add here any python package you need globally
        ]))
    ];
  };
}

