{ stdenv, fetchFromGitHub, gtk3, pantheon, breeze-icons, gnome-icon-theme, hicolor-icon-theme }:

stdenv.mkDerivation rec {
  pname = "whitesur-dark-icons";
  version = "1.0.0";

  src = fetchFromGitHub {
    repo = "whitesur-dark-icons";
    owner = "wochap";
    rev = "d9dcf8e627a671ddaa0679d6ba87cf983d774019";
    sha256 = "1bdxdbz9ziw4k6rkd23axi6kff4g74qa936ib04qj8wbiyjybp8q";
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
