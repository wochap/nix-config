{
  pkgs,
  python3Packages,
  fetchurl,
  inputs,
}:

with python3Packages;
let
  six = buildPythonPackage rec {
    pname = "six";
    version = "1.17.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b7/ce/149a00dd41f10bc29e5921b496af8b574d8413afcd5e30dfa0ed46c2cc5e/six-1.17.0-py2.py3-none-any.whl";
      sha256 = "0x1jdic712dylbnyiqdj4xyxrlx0gaacynmbmkfiym4hxn8z68a7";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  pytz = buildPythonPackage rec {
    pname = "pytz";
    version = "2025.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/eb/38/ac33370d784287baa1c3d538978b5e2ea064d4c1b93ffbd12826c190dd10/pytz-2025.1-py2.py3-none-any.whl";
      sha256 = "0myy70qd1x9ya60msr0jybzbvw8vf9r2sfx2xp3flijvlpf25pc9";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  python-dateutil = buildPythonPackage rec {
    pname = "python-dateutil";
    version = "2.9.0.post0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/ec/57/56b9bcc3c9c6a792fcbaf139543cee77261f3651ca9da0c93f5c1221264b/python_dateutil-2.9.0.post0-py2.py3-none-any.whl";
      sha256 = "09q48zvsbagfa3w87zkd2c5xl54wmb9rf2hlr20j4a5fzxxvrcm8";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ six ];
  };
  vobject = buildPythonPackage rec {
    pname = "vobject";
    version = "0.9.9";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/68/20/6bba813bbd498c28edbbcf8253a6398cf4266ecf7bfa6129835c0a2bfbb1/vobject-0.9.9-py2.py3-none-any.whl";
      sha256 = "0gdcqvhiswh26nfa9g96w1niq10hhp450nax7a2d3x2w0s1bkg8g";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      python-dateutil
      pytz
      six
    ];
  };
in
buildPythonPackage {
  pname = "remind";
  version = "0.19.2+g${inputs.python-remind.shortRev or "dirty"}";
  src = inputs.python-remind;
  doCheck = false;
  buildInputs = [ ];
  checkInputs = [ ];
  nativeBuildInputs = [ ];
  propagatedBuildInputs = [
    python-dateutil
    pytz
    tzlocal
    vobject
  ];
}
