{ lib, pkgs }:
with pkgs;
python3Packages.buildPythonApplication rec {
  pname = "offlinemsmtp";
  version = "cb14dd9f5e62ad6d160ed3b0d6e1fc3cf936f3dd";
  format = "pyproject";

  src = pkgs.fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = version;
    sha256 = "sha256-0lnVM5hAFDUqWD2IMDlVqV4Ya47mvpjUfTf0e6P2ONg=";
  };

  nativeBuildInputs = [
    python3Packages.flit-core
    gobject-introspection
    python3Packages.setuptools
    wrapGAppsHook
  ];

  buildInputs = [ libnotify ];

  propagatedBuildInputs = with python3Packages; [
    inotify
    msmtp
    pass
    pygobject3
  ];

  pythonImportsCheck = [ "offlinemsmtp" ];

  # hook for gobject-introspection doesn't like strictDeps
  # https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  meta = with lib; {
    description = "msmtp wrapper allowing for offline use";
    homepage = "https://github.com/sumnerevans/offlinemsmtp";
    license = licenses.gpl3Plus;
  };
}
