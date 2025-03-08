{ pkgs, python3Packages, fetchurl }:

with python3Packages;
let
  six = buildPythonPackage rec {
    pname = "six";
    version = "1.17.0";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/b7/ce/149a00dd41f10bc29e5921b496af8b574d8413afcd5e30dfa0ed46c2cc5e/six-1.17.0-py2.py3-none-any.whl";
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
      url =
        "https://files.pythonhosted.org/packages/eb/38/ac33370d784287baa1c3d538978b5e2ea064d4c1b93ffbd12826c190dd10/pytz-2025.1-py2.py3-none-any.whl";
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
      url =
        "https://files.pythonhosted.org/packages/ec/57/56b9bcc3c9c6a792fcbaf139543cee77261f3651ca9da0c93f5c1221264b/python_dateutil-2.9.0.post0-py2.py3-none-any.whl";
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
      url =
        "https://files.pythonhosted.org/packages/68/20/6bba813bbd498c28edbbcf8253a6398cf4266ecf7bfa6129835c0a2bfbb1/vobject-0.9.9-py2.py3-none-any.whl";
      sha256 = "0gdcqvhiswh26nfa9g96w1niq10hhp450nax7a2d3x2w0s1bkg8g";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ python-dateutil pytz six ];
  };

  # tzdata = buildPythonPackage rec {
  #   pname = "tzdata";
  #   version = "2021.5-t";
  #   src = fetchurl {
  #     url =
  #       "https://files.pythonhosted.org/packages/a5/3a/0d12fac5618ff5396095a139b9c77cad79b65ed78c58bf7162cd512f52d5/tzdata-2021.5-py2.py3-none-any.whl";
  #     sha256 = "1xd8bgh4v12ajbw82k8lb7795w3hrlvl2yn9zif1xzpb48g4kviy";
  #   };
  #   format = "wheel";
  #   doCheck = false;
  #   buildInputs = [ ];
  #   checkInputs = [ ];
  #   nativeBuildInputs = [ ];
  #   propagatedBuildInputs = [ ];
  #   postInstall = ''
  #     ln -s /etc/localtime $out/lib/python3.10/site-packages/tzdata/zoneinfo/localtime
  #   '';
  # };
in buildPythonPackage rec {
  pname = "remind";
  version = "0.19.2";
  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/ae/73/8890665a5f86c71dbe8250463788fd4c736c099bd1195f109e5c3acb93ef/remind-0.19.2-py3-none-any.whl";
    sha256 = "16p1fv4wpbjjddnwpcdkrm1zpndylih47nfnlymngvn1yapvn1gs";
  };
  format = "wheel";
  doCheck = false;
  buildInputs = [ ];
  checkInputs = [ ];
  nativeBuildInputs = [ ];
  propagatedBuildInputs = [ python-dateutil vobject ];
}
