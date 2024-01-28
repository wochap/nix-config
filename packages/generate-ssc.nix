{ pkgs, stdenv, ... }:
metadata:

let domain = metadata.domain;
in stdenv.mkDerivation {
  name = "generate-ssc";
  version = "1.0.0";
  src = ./.;

  buildPhase = ''
    export CAROOT="$TMPDIR/mkcert"
    mkdir -p "$CAROOT"
    cd "$CAROOT"
    mkcert -install
    mkcert ${domain} "*.${domain}" localhost 127.0.0.1 ::1
  '';

  installPhase = ''
    export CAROOT="$TMPDIR/mkcert"
    mkdir -p $out
    cd "$CAROOT"
    cp ./* $out
  '';

  nativeBuildInputs = with pkgs; [ openssl nssTools mkcert ];
}
