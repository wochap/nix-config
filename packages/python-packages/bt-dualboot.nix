{ pkgs, python3Packages, fetchFromGitHub }:

with python3Packages;
buildPythonPackage rec {
  pname = "bt-dualboot";
  version = "bc8c949bea93ab7d0c4dc763a866e8531b4d95fa";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "Simon128";
    repo = pname;
    rev = version;
    hash = "sha256-WzN2ki3VHrScSVpAn+JVX2AUNfG6g7fy4+1LDAtso9k=";
  };

  doCheck = false;
  buildInputs = [ ];
  checkInputs = [ ];
  nativeBuildInputs = [ poetry-core ];
  propagatedBuildInputs = with pkgs; [ chntpw ];
}
