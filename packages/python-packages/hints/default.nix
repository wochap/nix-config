{
  pkgs,
  python3Packages,
  fetchFromGitHub,
}:

with python3Packages;
buildPythonApplication rec {
  pname = "hints";
  version = "1b23d729d59f5946426c0dc747cc722b2621b6ca";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "AlfredoSequeida";
    repo = "hints";
    rev = version;
    hash = "sha256-JhHoXnZeGBu9m2o3cRUky6Nc5uSc1DkS9V8420jEw+o=";
  };

  patches = [ ./disable-systemd-install.patch ];

  build-system = with pkgs; [
    setuptools
  ];

  propagatedBuildInputs = [
    pygobject3
    pillow
    pyscreenshot
    opencv-python
    evdev
    dbus-python
    pyatspi
    rich
  ];

  nativeBuildInputs = with pkgs; [
    gobject-introspection
    wrapGAppsHook3
    patch
    pkg-config
  ];

  buildInputs = with pkgs; [
    at-spi2-core
    gtk3
    gtk-layer-shell
    libwnck # for X11
    libevdev # For python-evdev
    dbus # For dbus-python
  ];

  preBuild = ''
    export HINTS_EXPECTED_BIN_DIR="$out/bin"
  '';

  makeWrapperArgs = [ "\${gappsWrapperArgs[@]}" ];
}
