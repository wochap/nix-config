{ stdenv, fetchFromGitHub, gtk-engine-murrine }:

stdenv.mkDerivation rec {
  pname = "whitesur-dark-theme";
  version = "1.0.0";

  src = fetchFromGitHub {
    repo = "whitesur-dark-theme";
    owner = "wochap";
    rev = "f7395a0d89564da0136f91588b012c9b6aff519a";
    sha256 = "1j8bsbyikj36gp1am19xhzljvpwbgd348px0gdf319za3sp6d0q7";
  };

  sourceRoot = ".";

  propagatedUserEnvPkgs = [ gtk-engine-murrine ];

  installPhase = ''
    mkdir -p $out/share/themes
    cp -a ./source $out/share/themes
    mv $out/share/themes/source $out/share/themes/WhiteSur-dark
  '';

  meta = with stdenv.lib; {
    description = "WhiteSur dark theme.";
    homepage = "https://github.com/wochap/WhiteSur-dark";
  };
}
