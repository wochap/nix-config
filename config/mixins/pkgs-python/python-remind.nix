{ pkgs, python3Packages, fetchurl }:

with python3Packages;
let
  six = buildPythonPackage rec {
    pname = "six";
    version = "1.16.0";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/d9/5a/e7c31adbe875f2abbb91bd84cf2dc52d792b5a01506781dbcf25c91daf11/six-1.16.0-py2.py3-none-any.whl";
      sha256 = "0m02dsi8lvrjf4bi20ab6lm7rr6krz7pg6lzk3xjs2l9hqfjzfwa";
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
    version = "2.8.2";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/36/7a/87837f39d0296e723bb9b62bbb257d0355c7f6128853c78955f57342a56d/python_dateutil-2.8.2-py2.py3-none-any.whl";
      sha256 = "1aaxjfp4lrz8c6qls3vdhw554lan3khy9afyvdcvrssk6kf067cn";
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
    version = "0.9.6.1";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/da/ce/27c48c0e39cc69ffe7f6e3751734f6073539bf18a0cfe564e973a3709a52/vobject-0.9.6.1.tar.gz";
      sha256 = "0081g4gngw28j7vw8101jk600wz4gzfrhf5myrqvn2mrfkn2llcn";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ python-dateutil ];
  };

  tzdata = buildPythonPackage rec {
    pname = "tzdata";
    version = "2021.5-t";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/a5/3a/0d12fac5618ff5396095a139b9c77cad79b65ed78c58bf7162cd512f52d5/tzdata-2021.5-py2.py3-none-any.whl";
      sha256 = "1xd8bgh4v12ajbw82k8lb7795w3hrlvl2yn9zif1xzpb48g4kviy";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
    postInstall = ''
      ln -s /etc/localtime $out/lib/python3.10/site-packages/tzdata/zoneinfo/localtime
    '';
  };
in buildPythonPackage rec {
  pname = "remind";
  version = "0.18.0";
  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/d5/25/9eb3bdc8f234787c5b8ce160ef28b23eb3da012f93ed28414ffb5955585f/remind-0.18.0-py3-none-any.whl";
    sha256 = "1msizyq535igpgb95kdni2rbwzazja1xsz0ganj9175jlszvfnvz";
  };
  format = "wheel";
  doCheck = false;
  buildInputs = [ ];
  checkInputs = [ ];
  nativeBuildInputs = [ ];
  propagatedBuildInputs = [ python-dateutil vobject tzdata ];
}
