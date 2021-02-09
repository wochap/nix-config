{ stdenv, fetchFromGitHub, gtk3, pantheon, breeze-icons, gnome-icon-theme, hicolor-icon-theme }:

stdenv.mkDerivation rec {
  pname = "whitesur-dark-icons";
  version = "1.0.0";

  src = fetchFromGitHub {
    repo = "whitesur-dark-icons";
    owner = "wochap";
    rev = "6b472c0abe4b05041e35fc9674e916b6315a60fb";
    sha256 = "10aacmrd3y6mfs6k7kn65vxbmlc8i79ip3sfb5ski7kwr1jw33b5";
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
