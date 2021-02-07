{ stdenv, fetchFromGitHub, gtk3, pantheon, breeze-icons, gnome-icon-theme, hicolor-icon-theme }:

stdenv.mkDerivation rec {
  pname = "horizon-icons";
  version = "1.0.0";

  # Clone repo in source folder
  src = fetchFromGitHub {
    repo = "Horizon";
    owner = "zodd18";
    rev = "b8204a1dfa627fa8f4fb5c49f8d941bd55ce8c3a";
    sha256 = "1nl20mwnris8acx3azkgnyl95kf9jvrq9knby72x7bl5m5z7k427";
  };

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
    cp -a .icons/horizon-icons $out/share/icons

    for theme in $out/share/icons/*; do
      gtk-update-icon-cache $theme
    done
  '';

  meta = with stdenv.lib; {
    description = "Horizon icons";
    homepage = "https://github.com/zodd18/Horizon";
  };
}
