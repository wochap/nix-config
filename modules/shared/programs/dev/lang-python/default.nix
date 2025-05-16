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
      uv # better pip
      pip
      pynvim # required by nvim

      # NOTE: add here any python package you need globally
      matplotlib
      python-dotenv
      requests
      datetime
      ics
      pdf2image
      html2text
      icalendar
      pytz
      tzlocal
    ]));
in {
  options._custom.programs.lang-python.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ pipx poetry pipenv python-final ];

    _custom.hm = {
      # adds ~/.local/bin folder to the PATH env var
      home.sessionPath = [ "$HOME/.local/bin" ];

      # env variable to be used within neovim config
      # NOTE: this variable changes every time you update Python pkgs
      # you may need to log out and log back in for changes to take effect
      home.sessionVariables.GLOBAL_PYTHON_FOLDER_PATH = "${python-final}";

      # HACK: to make mason.nvim work
      programs.zsh.initContent = ''
        # TODO: clear $HOME/.venv when updating python version
        if [ -d "$HOME/.venv" ]; then
          zsh-defer source "$HOME/.venv/bin/activate"
        else
          ${python-final}/bin/python -m venv "$HOME/.venv"
        fi
      '';
    };
  };
}

