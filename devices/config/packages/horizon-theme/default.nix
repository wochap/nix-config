{ stdenv, fetchFromGitHub, gtk-engine-murrine }:

stdenv.mkDerivation rec {
  pname = "horizon-theme";
  version = "1.0.0";

  # Clone repo in source folder
  src = fetchFromGitHub {
    repo = "Horizon";
    owner = "zodd18";
    rev = "b8204a1dfa627fa8f4fb5c49f8d941bd55ce8c3a";
    sha256 = "1nl20mwnris8acx3azkgnyl95kf9jvrq9knby72x7bl5m5z7k427";
  };

  sourceRoot = ".";

  propagatedUserEnvPkgs = [ gtk-engine-murrine ];

  installPhase = ''
    mkdir -p $out/share/themes
    cp -a ./source/.themes/horizon-theme $out/share/themes
  '';

  meta = with stdenv.lib; {
    description = "Horizon theme";
    homepage = "https://github.com/zodd18/Horizon";
  };
}
