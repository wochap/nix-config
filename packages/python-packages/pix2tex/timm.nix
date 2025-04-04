{ pkgs, python3Packages, }:

with python3Packages;
buildPythonPackage rec {
  pname = "timm";
  version = "0.5.4";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-XXuS5mp2xDIAmrqQ1RXqeogqrlc0FafFJp42F9+QHB8=";
  };

  nativeBuildInputs = with pkgs; [ setuptools wheel ];

  propagatedBuildInputs = with pkgs; [
    huggingface-hub
    pyyaml
    safetensors
    torch
    torchvision
  ];

  pythonImportsCheck = [ "timm" ];
}

