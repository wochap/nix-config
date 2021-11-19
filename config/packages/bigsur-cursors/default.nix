{ stdenv, lib, fetchzip }:

stdenv.mkDerivation rec {
  pname = "bigsur-cursors";
  version = "1.0.0";

  src = fetchzip {
    url = "https://github.com/ful1e5/apple_cursor/releases/download/v1.1.4/macOSBigSur.tar.gz";
    sha256 = "0ylw6ja3h5xdv9fd3lpgi5h6bl9pn8kscjci7wrj6b1lrpiyvjfi";
  };

  installPhase = ''
    install -dm 0755 $out/share/icons/bigsur-cursors
    cp -pr cursor.theme $out/share/icons/bigsur-cursors/cursor.theme
    cp -pr cursors $out/share/icons/bigsur-cursors/cursors
    cp -pr index.theme $out/share/icons/bigsur-cursors/index.theme
  '';

  meta = with lib; {
    description = "BigSur cursors";
    homepage = "https://github.com/ful1e5/apple_cursor";
  };
}
