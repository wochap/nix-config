{ pkgs, python3Packages, }:

let entmax = pkgs.callPackage ./entmax.nix { inherit pkgs; };
in with python3Packages;
buildPythonPackage rec {
  pname = "x-transformers";
  version = "0.15.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-loAhpd9AG0G2ymSaCgrOrdVvIyv62YgOoLGeFXHwsWg=";
  };

  nativeBuildInputs = [ setuptools wheel ];

  propagatedBuildInputs = [ einops torch packaging entmax ];

  pythonImportsCheck = [ "x_transformers" ];
}
