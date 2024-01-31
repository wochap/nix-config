{ lib, pkgs }:
with pkgs;
python3Packages.buildPythonApplication rec {
  pname = "offlinemsmtp";
  version = "unstable-2023-06-23";
  format = "pyproject";

  src = pkgs.fetchFromGitHub {
    owner = "sumnerevans";
    repo = pname;
    rev = "9dd0a8eec84aa62dfd4a4a7eae62e0733917e9b2";
    sha256 = "sha256-V4CDnpG8PZHs/0vA+6DvS5v9o08WRCQ0CKwmK1rGuY0=";
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
