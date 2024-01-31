{ lib, python3Packages, fetchurl, wayland, wlroots, ... }:

with python3Packages;
buildPythonPackage rec {
  pname = "riverwm-utils";
  version = "0.0.7-next";
  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/61/c0/023a2c41e156df34367183cc1f53859d622b3b7ef5d02e8fc69e22687261/riverwm_utils-0.0.7-py3-none-any.whl";
    sha256 = "3b0f821985ea9b93f3da079abb92cb76dcb36e025f4bcc40231207e3c690500a";
  };
  format = "wheel";
  doCheck = false;
  buildInputs = [ wayland wlroots ];
  checkInputs = [ ];
  nativeBuildInputs = [ ];
  propagatedBuildInputs =
    [ python3Packages.pywayland python3Packages.pywlroots ];
}
