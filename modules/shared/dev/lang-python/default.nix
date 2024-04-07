{ config, pkgs, lib, ... }:

let
  cfg = config._custom.dev.lang-python;
  packageOverrides =
    pkgs.prevstable-python.callPackage ./pip2nix/python-packages.nix {
      pkgs = pkgs.prevstable-python;
    };
  python =
    pkgs.prevstable-python.python311.override { inherit packageOverrides; };
  python-final = (python.withPackages (ps:
    with ps; [
      pip
      pynvim # required by nvim
      # NOTE: add here any python package you need globally
      html2text
      pytz
      icalendar
    ]));
in {
  options._custom.dev.lang-python.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ pipx poetry pipenv python-final ];

    # HACK: so pylint can resolve modules
    environment.sessionVariables.PYTHONPATH =
      [ "${python-final}/lib/python3.11/site-packages" "$PYTHONPATH" ];

    _custom.hm = {
      # HACK: to make mason.nvim work
      programs.zsh.initExtra = lib.mkBefore ''
        if [ -d "$HOME/.venv" ]; then
          zsh-defer source "$HOME/.venv/bin/activate"
        else
          ${python-final}/bin/python -m venv "$HOME/.venv"
        fi
      '';
    };
  };
}

