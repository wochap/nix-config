{ lib, stdenv, fetchFromGitHub, libxcb, pkgs }:

stdenv.mkDerivation rec {
  pname = "neeasade-wmutils-opt";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "neeasade";
    repo = "opt";
    rev = "b36b1ce72bc47ce82519ae493c0968ef39e4ce29";
    sha256 = "sha256-oOvRaayrXa3E9pjc3sYZBh3R+4trAWtcS4aJ3mXy+8o=";
  };

  buildInputs = [ pkgs.xorg.libxcb pkgs.xorg.xcbutil ];

  installFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "wmutils-like border programs.";
    homepage = "https://github.com/neeasade/opt";
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}
