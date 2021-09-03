{ lib, stdenv, fetchFromGitLab, pkgs }:

stdenv.mkDerivation rec {
  pname = "interception-both-shift-capslock";
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "zeertzjq";
    repo = pname;
    rev = "c8abceff8b96a9a809187cb8e82b98553e20f459";
    sha256 = "0s7balwqczqazb8f4b9w1nhycczx5r7ahkaj7l2hcqbgkrp67smk";
  };

  nativeBuildInputs = [];

  preConfigure = ''
    export PREFIX=$out
  '';

  meta = with lib; {
    homepage = "https://gitlab.com/zeertzjq/interception-both-shift-capslock";
    description = "An Interception Tools plugin to send Caps Lock when Shift keys on both sides are down.";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
