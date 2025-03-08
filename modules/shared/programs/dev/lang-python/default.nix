{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.lang-python;
  packageOverrides =
    pkgs.prevstable-python.callPackage ./pip2nix/python-packages.nix {
      pkgs = pkgs.prevstable-python;
    };
  python =
    pkgs.prevstable-python.python311.override { inherit packageOverrides; };
  python-final = (python.withPackages (ps:
    with ps; [
      pylint-venv
      pip
      pynvim # required by nvim
      # NOTE: add here any python package you need globally
      html2text
      icalendar
      pytz
      tzlocal
    ]));
in {
  options._custom.programs.lang-python.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ pipx poetry pipenv python-final ];

    # env variable to be used within neovim config
    environment.sessionVariables.GLOBAL_PYTHON_FOLDER_PATH = "${python-final}";

    _custom.hm = {
      home.sessionPath = [ "$HOME/.local/bin" ];

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

