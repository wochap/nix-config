{ stdenv, fetchFromGitHub, gtk3, pantheon, breeze-icons, gnome-icon-theme, hicolor-icon-theme }:

stdenv.mkDerivation rec {
  pname = "whitesur-dark-icons";
  version = "1.0.0";

  src = fetchFromGitHub {
    repo = "whitesur-dark-icons";
    owner = "wochap";
    rev = "3818a683791fa770b29d5b539389fd8857c1d608";
    sha256 = "14s9as2dgv5f6x1qjj763zdycv3mxm81879077i2bnhhjwhbxxbs";
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

  meta = with stdenv.lib; {
    description = "WhiteSur dark icon theme.";
    homepage = "https://github.com/wochap/whitesur-dark-icon-theme";
  };
}
