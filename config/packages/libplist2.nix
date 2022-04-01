{ lib, stdenv, autoreconfHook, fetchFromGitHub, pkg-config, enablePython ? false
, python ? null, glib }:

stdenv.mkDerivation rec {
  pname = "libplist";
  version = "2.2.11";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = "libplist-build";
    rev = "47be0a06cde875e663a3743396a0d900c9ade9f9";
    sha256 = "sha256-W+9yr0BaLm9VG8EhxwBGoz9R5C3dZ0KM2LWcUAKmsQI=";
  };

  sourceRoot = ".";

  # outputs = [ "bin" "dev" "out" ] ++ lib.optional enablePython "py";

  installPhase = ''
    cp -a ./source/* $out
  '';

  meta = with lib; {
    description =
      "A library to handle Apple Property List format in binary or XML";
    homepage = "https://github.com/libimobiledevice/libplist";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
