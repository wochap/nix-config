{ lib, pkgs }:

with pkgs;
python3Packages.buildPythonApplication rec {
  pname = "offlinemsmtp";
  version = "0.3.10";

  nativeBuildInputs =
    [ gobject-introspection python3Packages.setuptools wrapGAppsHook ];

  buildInputs = [ libnotify ];

  propagatedBuildInputs = with python3Packages; [
    msmtp
    pass
    pygobject3
    watchdog
  ];

  doCheck = false;

  # hook for gobject-introspection doesn't like strictDeps
  # https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  src = python3.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "sha256-7+f/kjl1QVaVG7FT5ByewoXbIsrQLsdRblDcIwYwjVE=";
  };

  meta = with lib; {
    description = "msmtp wrapper allowing for offline use";
    homepage = "https://git.sr.ht/~sumner/offlinemsmtp";
    license = licenses.gpl3Plus;
  };
}
