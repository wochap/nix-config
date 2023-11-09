{ lib, stdenv, fetchFromGitHub, pkg-config, wayland-scanner, wayland
, wayland-protocols, pango }:

stdenv.mkDerivation rec {
  pname = "dwl-state";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "MadcowOG";
    repo = "dwl-state";
    rev = "ipc-v2";
    sha256 = "sha256-GTtt+P+iGW1uQdedVUFovxy1HZO2lvp6mg4sZIOUSXA=";
  };

  nativeBuildInputs = [ pkg-config wayland-scanner ];
  buildInputs = [ pango wayland wayland-protocols ];
  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    homepage = "https://github.com/MadcowOG/dwl-state/tree/ipc-v2";
    description =
      "Command-line tool to get dwl's state through the dwl-ipc protocol";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
