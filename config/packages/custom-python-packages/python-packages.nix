# Generated by pip2nix 0.8.0.dev1
# See https://github.com/nix-community/pip2nix

{ pkgs, fetchurl, fetchgit, fetchhg }:

self: super: {
  "anchor-kr" = super.buildPythonPackage rec {
    pname = "anchor-kr";
    version = "0.1.3";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/dd/46/c96feb94c9101ca57b9d612b6510b06da31d31321e5c54fca6cb4a6a0adf/anchor-kr-0.1.3.tar.gz";
      sha256 = "1gsbxjahyan617dj91q6bcjg6njk47vkjk6w4l1d56rmznv5bh0g";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "animdl" = super.buildPythonPackage rec {
    pname = "animdl";
    version = "1.7.11";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/83/77/e22e7e5208df90fc7f2b9dd60c19bef7beb0a45396f7ecd2bd27281536e5/animdl-1.7.11-py3-none-any.whl";
      sha256 = "0gh3yb2amj0c9r58vpm5k1y6w2mm2cgxfghs18yg1xf1wychx1f8";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."anchor-kr"
      self."anitopy"
      self."click"
      self."comtypes"
      self."cssselect"
      self."httpx"
      self."lxml"
      self."packaging"
      self."pkginfo"
      self."pycryptodomex"
      self."pyyaml"
      self."regex"
      self."rich"
      self."tqdm"
      self."yarl"
    ];
  };
  "anitopy" = super.buildPythonPackage rec {
    pname = "anitopy";
    version = "2.1.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/d3/8b/3da3f8ba73b8e4e5325a9ecbd6780f4dc9f41c98cc1c6a897800c4f85979/anitopy-2.1.1.tar.gz";
      sha256 = "09lfk036mjamsgzm4lmdwrrsbs3mvhxvakiz643f8zlig36rfnsi";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "anyio" = super.buildPythonPackage rec {
    pname = "anyio";
    version = "3.6.2";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/77/2b/b4c0b7a3f3d61adb1a1e0b78f90a94e2b6162a043880704b7437ef297cad/anyio-3.6.2-py3-none-any.whl";
      sha256 = "1qsi382l4607lsjz8k8azhqlwa2h2824ap8wxprjwahd4yyk5gpv";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."idna"
      self."sniffio"
    ];
  };
  "certifi" = super.buildPythonPackage rec {
    pname = "certifi";
    version = "2022.12.7";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/71/4c/3db2b8021bd6f2f0ceb0e088d6b2d49147671f25832fb17970e9b583d742/certifi-2022.12.7-py3-none-any.whl";
      sha256 = "065wqxligjai8la891i71s921q7xmpyc3krixhc6fvcjbqpj7lsa";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "click" = super.buildPythonPackage rec {
    pname = "click";
    version = "8.1.3";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/c2/f1/df59e28c642d583f7dacffb1e0965d0e00b218e0186d7858ac5233dce840/click-8.1.3-py3-none-any.whl";
      sha256 = "0j6vn6ayxq1bqs1v64r90sarg05hj6rxj4w29vs0k9hmrcrq2kdv";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "comtypes" = super.buildPythonPackage rec {
    pname = "comtypes";
    version = "1.1.14";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/2c/c3/912cf11dab12ef61841242f588692d940ad1068358bff14d322267707d36/comtypes-1.1.14-py2.py3-none-any.whl";
      sha256 = "1gc7bbbic943q3bh5n34rdxp8y1ixr8dq15yjzm5w47ycpff5nvw";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "cssselect" = super.buildPythonPackage rec {
    pname = "cssselect";
    version = "1.2.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/06/a9/2da08717a6862c48f1d61ef957a7bba171e7eefa6c0aa0ceb96a140c2a6b/cssselect-1.2.0-py2.py3-none-any.whl";
      sha256 = "0pnkkx6db5gk93iwsvwpj66j9zvfinvbdjzcslzc0q0bq7q8a66s";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "h11" = super.buildPythonPackage rec {
    pname = "h11";
    version = "0.14.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/95/04/ff642e65ad6b90db43e668d70ffb6736436c7ce41fcc549f4e9472234127/h11-0.14.0-py3-none-any.whl";
      sha256 = "0qd7z9p38dwx215048q708vd1sn2abdh1mb3hg66ii2ip324mzp3";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "httpcore" = super.buildPythonPackage rec {
    pname = "httpcore";
    version = "0.16.3";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/04/7e/ef97af4623024e8159993b3114ce208de4f677098ae058ec5882a1bf7605/httpcore-0.16.3-py3-none-any.whl";
      sha256 = "1h4xjk1b57p1sxxphz146x8camkh66wgxr5xhjh8m4sag04bf7ys";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."anyio"
      self."certifi"
      self."h11"
      self."sniffio"
    ];
  };
  "httpx" = super.buildPythonPackage rec {
    pname = "httpx";
    version = "0.23.3";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/ac/a2/0260c0f5d73bdf06e8d3fc1013a82b9f0633dc21750c9e3f3cb1dba7bb8c/httpx-0.23.3-py3-none-any.whl";
      sha256 = "1mhhwfrrkd3vl394gsal06jana9xkf3gjsndy0jflm0jkg7gq4d2";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."certifi"
      self."httpcore"
      self."rfc3986"
      self."sniffio"
    ];
  };
  "idna" = super.buildPythonPackage rec {
    pname = "idna";
    version = "3.4";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/fc/34/3030de6f1370931b9dbb4dad48f6ab1015ab1d32447850b9fc94e60097be/idna-3.4-py3-none-any.whl";
      sha256 = "1hn54ps4kgv2fmyvfaks38sgrvjc1cn4834sh7gadsx3x9wpxdwh";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "lxml" = super.buildPythonPackage rec {
    pname = "lxml";
    version = "4.9.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/70/bb/7a2c7b4f8f434aa1ee801704bf08f1e53d7b5feba3d5313ab17003477808/lxml-4.9.1.tar.gz";
      sha256 = "0grczyrrq2rbwhvpri15cyhv330s494vbz3js3jky8xp5c2rnx7y";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [
      pkgs.libxslt
      pkgs.libxml2
    ];
    propagatedBuildInputs = [];
  };
  "markdown-it-py" = super.buildPythonPackage rec {
    pname = "markdown-it-py";
    version = "2.2.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/bf/25/2d88e8feee8e055d015343f9b86e370a1ccbec546f2865c98397aaef24af/markdown_it_py-2.2.0-py3-none-any.whl";
      sha256 = "0c6cs28g2s5m500rf15g3dirn4j6q4nn36bvqjndjw81hz8zhdas";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."mdurl"
    ];
  };
  "mdurl" = super.buildPythonPackage rec {
    pname = "mdurl";
    version = "0.1.2";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b3/38/89ba8ad64ae25be8de66a6d463314cf1eb366222074cfda9ee839c56a4b4/mdurl-0.1.2-py3-none-any.whl";
      sha256 = "1y5qjqhmq2nm7xj6w5rrp503r7jhj7zr2qcnr6gs858nwm0ql044";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "multidict" = super.buildPythonPackage rec {
    pname = "multidict";
    version = "6.0.4";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/4a/15/bd620f7a6eb9aa5112c4ef93e7031bcd071e0611763d8e17706ef8ba65e0/multidict-6.0.4.tar.gz";
      sha256 = "0jfsq7dnaja8jnd4ih02fhp6ic2ryhn7zfg7q19n9dzgj9j90rin";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "packaging" = super.buildPythonPackage rec {
    pname = "packaging";
    version = "23.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/ed/35/a31aed2993e398f6b09a790a181a7927eb14610ee8bbf02dc14d31677f1c/packaging-23.0-py3-none-any.whl";
      sha256 = "1ch201bz087xfagzsy0hdyxz719bg9gq804vqacqrrn3jr2c2jki";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "pkginfo" = super.buildPythonPackage rec {
    pname = "pkginfo";
    version = "1.9.6";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b3/f2/6e95c86a23a30fa205ea6303a524b20cbae27fbee69216377e3d95266406/pkginfo-1.9.6-py3-none-any.whl";
      sha256 = "0ip5ynd889hjdhs2lhddmmhh6sr9ipbvzxwwrjgic8jsdmd5ayjb";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "pycryptodomex" = super.buildPythonPackage rec {
    pname = "pycryptodomex";
    version = "3.14.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/24/40/e249ac3845a2333ce50f1bb02299ffb766babdfe80ca9d31e0158ad06afd/pycryptodomex-3.14.1.tar.gz";
      sha256 = "1wn1ccr5fqps4hy88ydgfd0hd8pc2jfmpizdfj6armhz1386xrrc";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "pygments" = super.buildPythonPackage rec {
    pname = "pygments";
    version = "2.14.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/0b/42/d9d95cc461f098f204cd20c85642ae40fbff81f74c300341b8d0e0df14e0/Pygments-2.14.0-py3-none-any.whl";
      sha256 = "05r7p29qh4qps5lsniva5jym27vkzkyqpbq3wc6pqa3i4yyxfyzs";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "pyyaml" = super.buildPythonPackage rec {
    pname = "pyyaml";
    version = "6.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/36/2b/61d51a2c4f25ef062ae3f74576b01638bebad5e045f747ff12643df63844/PyYAML-6.0.tar.gz";
      sha256 = "18imkjacvpxfgg1lbpraqywx3j7hr5dv99d242byqvrh2jf53yv8";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "regex" = super.buildPythonPackage rec {
    pname = "regex";
    version = "2022.10.31";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/27/b5/92d404279fd5f4f0a17235211bb0f5ae7a0d9afb7f439086ec247441ed28/regex-2022.10.31.tar.gz";
      sha256 = "10vyqyz9pslld1rxvv75i4b610waji8sbrpfg92zh6wsv8hqkad3";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "rfc3986" = super.buildPythonPackage rec {
    pname = "rfc3986";
    version = "1.5.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/c4/e5/63ca2c4edf4e00657584608bee1001302bbf8c5f569340b78304f2f446cb/rfc3986-1.5.0-py2.py3-none-any.whl";
      sha256 = "15raf577150bdnjqvr89n9xnc2cllw5dy4mh32r3ihhxbcgnwvd8";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."idna"
    ];
  };
  "rich" = super.buildPythonPackage rec {
    pname = "rich";
    version = "13.3.3";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/42/5c/f44fc88bad850c4a20711a3349ec0e8bc50fece8d8b32c962d2aab70ea2b/rich-13.3.3-py3-none-any.whl";
      sha256 = "0cv33ifvjqbhxscqnd7n9x3d2g1sax2bms9pif78w5x14rnps32l";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."markdown-it-py"
      self."pygments"
    ];
  };
  "sniffio" = super.buildPythonPackage rec {
    pname = "sniffio";
    version = "1.3.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/c3/a0/5dba8ed157b0136607c7f2151db695885606968d1fae123dc3391e0cfdbf/sniffio-1.3.0-py3-none-any.whl";
      sha256 = "112k8azxisfcwpvx36rpgisxf15lxv0zgaza5snvggsv3v7gvkpf";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "tqdm" = super.buildPythonPackage rec {
    pname = "tqdm";
    version = "4.65.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/e6/02/a2cff6306177ae6bc73bc0665065de51dfb3b9db7373e122e2735faf0d97/tqdm-4.65.0-py3-none-any.whl";
      sha256 = "0wcnkv4ysw5a61p2w71qp7hzzs0vccic1vmwba0k5q9pzqbkmxf4";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
  "yarl" = super.buildPythonPackage rec {
    pname = "yarl";
    version = "1.8.2";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/c4/1e/1b204050c601d5cd82b45d5c8f439cb6f744a2ce0c0a6f83be0ddf0dc7b2/yarl-1.8.2.tar.gz";
      sha256 = "0qhm1dwwd8wp3fwh88qrip23b19jymmvy0l6jz83l0g3qq139m29";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [
      self."idna"
      self."multidict"
    ];
  };
}
