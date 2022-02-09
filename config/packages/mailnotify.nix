{ lib, pkgs }:

with pkgs;
python3Packages.buildPythonApplication rec {
  pname = "mailnotify";
  version = "unstable-2021-08-29";
  format = "pyproject";

  nativeBuildInputs =
    [ gobject-introspection python3Packages.poetry wrapGAppsHook ];

  buildInputs = [ libnotify ];

  propagatedBuildInputs = with python3Packages; [ bleach pygobject3 watchdog ];

  # no tests
  doCheck = false;

  # hook for gobject-introspection doesn't like strictDeps
  # https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  src = fetchFromGitHub {
    owner = "sumnerevans";
    repo = pname;
    rev = "cc2040d9518af8347dd01eff22c70c8386740290";
    sha256 = "sha256-mvGUfmHMW+Po6G9cVu5OiDKHI6Bw2yAXc2Unnuhgr5k=";
  };

  meta = with lib; {
    description =
      "A small program that notifies when mail has arrived in your mail directory.";
    homepage = "https://git.sr.ht/~sumner/mailnotify";
    license = licenses.gpl3Plus;
  };
}
