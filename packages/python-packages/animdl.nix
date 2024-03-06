{ pkgs, python3Packages, fetchurl, fetchFromGitHub }:

with python3Packages;
let
  anchor-kr = buildPythonPackage rec {
    pname = "anchor-kr";
    version = "0.1.3";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/dd/46/c96feb94c9101ca57b9d612b6510b06da31d31321e5c54fca6cb4a6a0adf/anchor-kr-0.1.3.tar.gz";
      sha256 = "1gsbxjahyan617dj91q6bcjg6njk47vkjk6w4l1d56rmznv5bh0g";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };

  anitopy = buildPythonPackage rec {
    pname = "anitopy";
    version = "2.1.1";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/d3/8b/3da3f8ba73b8e4e5325a9ecbd6780f4dc9f41c98cc1c6a897800c4f85979/anitopy-2.1.1.tar.gz";
      sha256 = "09lfk036mjamsgzm4lmdwrrsbs3mvhxvakiz643f8zlig36rfnsi";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };

  comtypes = buildPythonPackage rec {
    pname = "comtypes";
    version = "1.1.14";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/2c/c3/912cf11dab12ef61841242f588692d940ad1068358bff14d322267707d36/comtypes-1.1.14-py2.py3-none-any.whl";
      sha256 = "1gc7bbbic943q3bh5n34rdxp8y1ixr8dq15yjzm5w47ycpff5nvw";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };

  pycryptodomex = buildPythonPackage rec {
    pname = "pycryptodomex";
    version = "3.14.1";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/24/40/e249ac3845a2333ce50f1bb02299ffb766babdfe80ca9d31e0158ad06afd/pycryptodomex-3.14.1.tar.gz";
      sha256 = "1wn1ccr5fqps4hy88ydgfd0hd8pc2jfmpizdfj6armhz1386xrrc";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };

  rich = buildPythonPackage rec {
    pname = "rich";
    version = "13.3.3";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/42/5c/f44fc88bad850c4a20711a3349ec0e8bc50fece8d8b32c962d2aab70ea2b/rich-13.3.3-py3-none-any.whl";
      sha256 = "0cv33ifvjqbhxscqnd7n9x3d2g1sax2bms9pif78w5x14rnps32l";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = with python3Packages; [ markdown-it-py pygments ];
  };

  lxml = buildPythonPackage rec {
    pname = "lxml";
    version = "4.9.1";

    src = fetchFromGitHub {
      owner = "lxml";
      repo = "lxml";
      rev = "refs/tags/lxml-4.9.1";
      sha256 = "sha256-5MJw3ciXYnfctSNcemJ/QJGKAaYpadvdbFhkc8+pmPM=";
    };

    buildInputs = with pkgs; [ libxml2 libxslt zlib ];
    checkInputs = [ ];
    # setuptoolsBuildPhase needs dependencies to be passed through nativeBuildInputs
    nativeBuildInputs = with pkgs; [
      libxml2.dev
      libxslt.dev
      python3Packages.cython
    ];
    propagatedBuildInputs = [ ];

    # tests are meant to be ran "in-place" in the same directory as src
    doCheck = false;
  };
in buildPythonPackage rec {
  pname = "animdl";
  version = "1.7.22";
  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/f3/43/6231c57feb02fe49c2cc2cbd3d40f1a6eeb3c23c93aa4018182364e3a49a/animdl-1.7.22-py3-none-any.whl";
    sha256 = "1l373ya31hqci9jalqs6px9j64gn03wyiacsjmxhmn4si6z37fal";
  };
  format = "wheel";
  doCheck = false;
  buildInputs = [ ];
  checkInputs = [ ];
  nativeBuildInputs = [ ];
  propagatedBuildInputs = [
    anchor-kr
    anitopy
    python3Packages.click
    comtypes
    python3Packages.cssselect
    python3Packages.httpx
    lxml
    python3Packages.packaging
    python3Packages.pkginfo
    pycryptodomex
    python3Packages.pyyaml
    python3Packages.regex
    rich
    python3Packages.tqdm
    python3Packages.yarl
  ];
}
