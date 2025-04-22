{ pkgs, python3Packages, fetchFromGitHub }:

with python3Packages;
buildPythonApplication rec {
  pname = "hints";
  version = "8ae81d866a991a7751b3818014a0cad015b6a440";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "AlfredoSequeida";
    repo = "hints";
    rev = version;
    hash = "sha256-c46EmdIVyAYmDhRgVc8Roump/DwHynKpj2/7mzxaNiY=";
  };

  patches = [ ./disable-systemd-install.patch ];

  build-system = with pkgs; [ setuptools gtk-layer-shell ];

  propagatedBuildInputs = with pkgs; [
    pygobject3
    pillow
    pyscreenshot
    opencv-python
    evdev
    dbus-python
    pyatspi
  ];

  nativeBuildInputs = with pkgs; [
    gobject-introspection
    wrapGAppsHook3
    patch
    pkg-config
  ];

  buildInputs = with pkgs; [
    at-spi2-core
    libwnck # for X11
    libevdev # For python-evdev
    dbus # For dbus-python
  ];

  preBuild = ''
    export HINTS_EXPECTED_BIN_DIR="$out/bin"
  '';

  makeWrapperArgs = [ "\${gappsWrapperArgs[@]}" ];
}
