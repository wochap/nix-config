{ stdenv, lib, fetchFromGitHub, gtk3, pantheon, breeze-icons, gnome-icon-theme, hicolor-icon-theme }:

stdenv.mkDerivation rec {
  pname = "whitesur-dark-icons";
  version = "1.0.0";

  src = fetchFromGitHub {
    repo = "whitesur-dark-icons";
    owner = "wochap";
    rev = "1d38b66f710db7cded600259b544249ce7d84f20";
    sha256 = "181smsqgiyr3d35bkbxb8sbcqb424l920c27q4yp4qpxspjgsy3k";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    gtk3
  ];

  propagatedBuildInputs = [
    pantheon.elementary-icon-theme
    breeze-icons
    gnome-icon-theme
    hicolor-icon-theme
  ];

  dontDropIconThemeCache = true;

  installPhase = ''
    mkdir -p $out/share/icons
    cp -a ./source/* $out/share/icons

    for theme in $out/share/icons/*; do
      gtk-update-icon-cache $theme
    done
  '';

  meta = with lib; {
    description = "WhiteSur dark icons.";
    homepage = "https://github.com/wochap/whitesur-dark-icons";
  };
}
