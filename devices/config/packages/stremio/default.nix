{ pkgs ? import <nixpkgs> {}, ... }:

# source: https://gist.githubusercontent.com/jasonwhite/d32f5806921471c857148276bfd32806/raw/b4692118746f8dfa40ffeb1968760e444ad75a83/stremio.nix
# source: https://github.com/alexandru-balan/Stremio-Install-Scripts/blob/master/installStremioArch.sh
let
  serverJS = pkgs.fetchurl {
    url = "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v4.4.132/server.js";
    sha256 = "0pjwlk5h39kg5z8fpd6f2dmddmqszjardgazg3vrnz4569kwb1yd";
  };
in
pkgs.qt5.mkDerivation rec {
  name = "stremio";

  nativeBuildInputs = with pkgs; [
    # NOTE: don't change order
    which
    qt5.qmake
    cmake
  ];
  buildInputs = with pkgs; [
    ffmpeg
    gcc
    librsvg
    mpv
    nodejs
    openssl
    qt5.qtbase
    qt5.qtquickcontrols
    qt5.qtquickcontrols2
    qt5.qtwebengine
    wget

    qt5.qtdeclarative
    qt5.qttools
    qt5.qttranslations
    qt5.qtwebchannel
  ];

  dontWrapQtApps = true;
  preFixup = ''
    wrapQtApp "$out/opt/stremio/stremio" --prefix PATH : "$out/opt/stremio"
  '';

  src = pkgs.fetchgit {
    url = "https://github.com/Stremio/stremio-shell";
    rev = "v4.4.132";
    sha256 = "116148al678k4b9bm8j7gamvdb00jnvs3z48fgdpdz6a4jyawx9i";
    fetchSubmodules = true;
  };

  buildPhase = ''
    cp ${serverJS} server.js
    qmake
    make -f release.makefile PREFIX="$out/"
  '';

  installPhase = ''
    make -f release.makefile install PREFIX="$out/"
  '';
}
