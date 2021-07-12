{ stdenv, lib, python3, python3Packages, fetchFromGitHub }:

let version = "2.0"; in

python3Packages.buildPythonApplication {
  name = "zscroll-${version}";
  # don't prefix with python version
  namePrefix = "";

  src = fetchFromGitHub {
    owner = "noctuid";
    repo = "zscroll";
    rev = "011269a0339c78beb900cdcac1fb7bac374a5464";
    sha256 = "1zibcdv7zib7rgfp6rgyjl3ch9754jp06bwpxxxcflpkvanqbahd";
  };

  doCheck = false;

  propagatedBuildInputs = [ python3 ];

  meta = with lib; {
    description = "A text scroller for use with panels and shells";
    homepage = "https://github.com/noctuid/zscroll";
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
