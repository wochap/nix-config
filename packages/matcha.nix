{ lib, pkgs, stdenv, fetchFromGitea, pkg-config, wayland
, wayland-protocols }:

stdenv.mkDerivation rec {
  pname = "matcha";
  version = "1.1.1";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "wochap";
    repo = "matcha";
    rev = "702ecf956202bd0f72a5e3d951e3d751d69b2ed3";
    hash = "sha256-wlmfCXX9pDwP47Xix51umkJ5RdfSzpeBOQF6lFFvDVQ=";
  };

  nativeBuildInputs = with pkgs; [ meson ninja pkg-config ];
  buildInputs = with pkgs; [ wayland wayland-protocols ];

  dontAddPrefix = true;
  mesonFlags = [ "--buildtype=release" "-Dprefix=${placeholder "out"}" ];

  meta = with lib; {
    homepage = "https://codeberg.org/QuincePie/matcha";
    description = "An Idle Inhibitor for Wayland";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

