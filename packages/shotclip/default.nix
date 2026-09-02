{
  lib,
  stdenv,
  inputs,
  pkg-config,
  wayland-scanner,
  glib,
  wayland,
  wayland-protocols,
}:

stdenv.mkDerivation {
  pname = "shotclip";
  version = "0+g${inputs.shotclip.shortRev or "dirty"}";

  src = inputs.shotclip;

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];
  buildInputs = [
    glib
    wayland
    wayland-protocols
  ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "Put files on the Wayland clipboard with Nautilus-compatible MIME types";
    homepage = "https://github.com/jq6l43d1/shotclip";
    license = lib.licenses.gpl3Plus;
    mainProgram = "shotclip";
    platforms = lib.platforms.linux;
  };
}
