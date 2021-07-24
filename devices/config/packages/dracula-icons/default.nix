{ stdenv, lib, fetchFromGitHub, gtk3, papirus-icon-theme, pantheon, breeze-icons, gnome-icon-theme, hicolor-icon-theme }:

stdenv.mkDerivation rec {
  pname = "dracula-icons";
  version = "1.0.0";

  src = fetchFromGitHub {
    repo = "dracula-icons";
    owner = "wochap";
    rev = "1716ed75a78489560d45dc2b3e0116c051f18355";
    sha256 = "1fqa5j7axrr5l13sigbry64smhrfrwqxqc4v30j1ipkqk9wah7sj";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    gtk3
  ];

  propagatedBuildInputs = [
    papirus-icon-theme
    breeze-icons
    pantheon.elementary-icon-theme
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
    description = "WhiteSur dark icon theme.";
    homepage = "https://github.com/wochap/dracula-icons";
  };
}
