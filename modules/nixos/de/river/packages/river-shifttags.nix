{ lib, stdenv, fetchFromGitLab, wayland-scanner, wayland }:

stdenv.mkDerivation rec {
  pname = "lswt";
  version = "1.0.4";

  src = fetchFromGitLab {
    owner = "akumar-xyz";
    repo = "river-shifttags";
    rev = "fd1e68de1c8c4966684d26830fe64e6a178705a2";
    hash = "sha256-BO4fXDDnql02DAFIDhHy5jof9EX0UeHa1yLD+fV9T1M=";
  };

  nativeBuildInputs = [ wayland-scanner ];
  buildInputs = [ wayland ];

  makeFlags = [ "DESTDIR=${placeholder "out"}" "PREFIX=" ];

  meta = with lib; {
    description =
      "A small utility for the river Wayland compositor to rotate the focused tags. Useful for focusing next/prev tag, or rotating the whole tagmask if multiple tags are in focus.";
    homepage = "https://gitlab.com/akumar-xyz/river-shifttags";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
