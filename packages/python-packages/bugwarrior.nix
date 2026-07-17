{ pkgs, python3Packages, fetchFromGitHub, fetchurl, fetchpatch }:

with python3Packages;
let
  ini2toml = buildPythonPackage rec {
    pname = "ini2toml";
    version = "0.15";
    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/ea/6d/a78a58b1d2007ebce56f1dc745b2763d4ba5a4b6faadca7dc034297c04c8/ini2toml-0.15-py3-none-any.whl";
      sha256 =
        "ad97b4abed0930b2682f232d874e17ce01a14c2b6b1d0461b363fd8366411a8d";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  taskw3 = buildPythonPackage rec {
    pname = "taskw";
    version = "2.0.0";
    pyproject = true;
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-EQm9+b3nqbMqUAejAsh4MD/2UYi2QiWsdKMomkxUi90=";
    };
    doCheck = false;
    patches = [
      (fetchpatch {
        url =
          "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/master/pkgs/development/python-modules/taskw/support-relative-path-in-taskrc.patch";
        sha256 = "sha256-9LXsGdB/g+YhvjP2rr1btsXBFo534htQXIq3bUSzER8=";
      })
      # Remove when https://github.com/ralphbean/taskw/pull/151 is merged.
      (fetchpatch {
        url =
          "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/master/pkgs/development/python-modules/taskw/use-template-for-taskwarrior-install-path.patch";
        sha256 = "sha256-onU6h1nMTPKNpPH1M0/uGYtFXE5Y9KuYg7mDSSMPSoM=";
      })
    ];
    postPatch = ''
      substituteInPlace taskw/warrior.py \
        --replace '@@taskwarrior@@' '${pkgs.taskwarrior3}'
    '';
    build-system = [ setuptools ];
    buildInputs = [ pkgs.taskwarrior3 distutils ];
    dependencies = [ kitchen python-dateutil pytz ];
    nativeCheckInputs = [ pytest7CheckHook ];
  };
in buildPythonPackage rec {
  pname = "bugwarrior";
  version = "2.0.0-unstable-2025-08-11";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "GothenburgBitFactory";
    repo = "bugwarrior";
    rev = "963fa8720668f0a773670ac88ddb482054f19b80";
    hash = "sha256-PZDu+GBALnDfsagSyNXZ4UTdexLtvC5AofdsGDGP344=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace 'license = "GPL-3.0-or-later"' 'license = { file = "LICENSE.txt" }' \
      --replace 'license-files = ["LICENSE.txt"]' "" \
      --replace 'packages = ["bugwarrior"]' 'packages.find = { where = ["."] }'
  '';

  nativeBuildInputs = with pkgs; [
    gobject-introspection
    wrapGAppsHook3
    wrapGAppsHook4
  ];

  propagatedBuildInputs = [
    # core
    click
    dogpile-cache
    email-validator # pydantic requires this for email validation
    jinja2
    lockfile
    pydantic
    python-dateutil
    pytz
    requests
    taskw3
    tomli
    pygobject3
    pkgs.libnotify

    # optionals
    debianbts
    python-bugzilla
    google-api-python-client
    google-auth-oauthlib
    ini2toml
    jira
    # kanboard
    keyring
    # phabricator
    todoist-api-python
    offtrac
  ];

  doCheck = false;
}

