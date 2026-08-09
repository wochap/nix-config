{
  lib,
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonApplication rec {
  pname = "supertonic";
  version = "1.3.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Q2fo9hr+phjayUj2vuVf7UchrWbKLT/JB3GipmdAcx4=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with python3Packages; [
    fastapi
    huggingface-hub
    numpy
    onnxruntime
    pydantic
    python-multipart
    soundfile
    uvicorn
  ];

  pythonImportsCheck = [ "supertonic" ];

  meta = {
    description = "High-quality on-device text-to-speech synthesis with ONNX Runtime";
    homepage = "https://github.com/supertone-inc/supertonic-py";
    license = lib.licenses.mit;
    mainProgram = "supertonic";
    platforms = lib.platforms.unix;
  };
}
