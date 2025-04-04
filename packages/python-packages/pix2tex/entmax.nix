{ pkgs, python3Packages, }:

with python3Packages;
buildPythonPackage rec {
  pname = "entmax";
  version = "1.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-HNlyHDSTWCTgccjCCQBxHK1gw9hLyeRmjzt6iHO/Ys8=";
  };

  nativeBuildInputs = [ setuptools wheel ];

  propagatedBuildInputs = [ torch ];

  pythonImportsCheck = [ "entmax" ];
}
