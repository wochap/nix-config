{ pkgs, python3Packages, fetchFromGitHub }:

with python3Packages;
buildPythonPackage rec {
  pname = "vidcutter";
  version = "6.0.5.1-next";
  src = fetchFromGitHub {
    owner = "ozmartian";
    repo = "vidcutter";
    rev = "591a60b0eb78e7103cabf19297b4290eefbb04fe";
    hash = "sha256-JYIjdMj2LTSqxZO1kz2ttJ9Ga18wtByn4PabuqVG2Hw=";
  };
  doCheck = false;
  buildInputs = [ ];
  checkInputs = [ ];
  nativeBuildInputs = [ ];
  propagatedBuildInputs = [
    pkgs.mediainfo
    pkgs.mpv
    python3Packages.pyopengl
    python3Packages.simplejson
    python3Packages.pyqt5
  ];
}
