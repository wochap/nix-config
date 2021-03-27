# with import <nixpkgs> {};
{
  pkgs,
  lib,
  pkg-config,
  fetchFromGitHub,
  glib,
  atk,
  cairo,
  pango,
  gdk-pixbuf-xlib,
  gtk3,
  gtkmm3,
  ...
}:

let mkRustPlatform = pkgs.callPackage ./mk-rust-platform.nix {};
    rustPlatform = mkRustPlatform {
      date = "2021-02-08";
      channel = "nightly";
    };
in
rustPlatform.buildRustPackage rec {
  pname = "eww";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "elkowar";
    repo = "eww";
    rev = "4da676e38b82db8d1ff4844376d65ada3d55772e";
    sha256 = "15rr35hxn2cplmg3icjylhr2rpp3d3l7qp1rlgc8jlqh4sb5a1i2";
  };

  cargoSha256 = "1y3zl2jf823akca7cdwiga6fc9qp9gp8pcxhmx49s78ph3ygqpm9";

  nativeBuildInputs = [
    pkg-config
  ];

  # TODO: remove unused dependencies
  buildInputs = [
    glib
    atk
    cairo
    pango
    gdk-pixbuf-xlib
    gtk3
    gtkmm3
  ];

  meta = with lib; {
    homepage = https://github.com/elkowar/eww;
    description = "ElKowar's wacky widgets";
  };
}
