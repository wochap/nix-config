{ lib, pkgs ? import <nixpkgs> {}, ... }:

# source: https://github.com/lucasew/nixcfg/blob/339c797b63006d9f5e944c3f83b822b1bdf35ac2/packages/stremio.nix
# source: https://gist.githubusercontent.com/jasonwhite/d32f5806921471c857148276bfd32806/raw/b4692118746f8dfa40ffeb1968760e444ad75a83/stremio.nix
# source: https://github.com/alexandru-balan/Stremio-Install-Scripts/blob/master/installStremioArch.sh
let
  version = "4.4.132";
  serverJS = pkgs.fetchurl {
    url = "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v${version}/server.js";
    sha256 = "0pjwlk5h39kg5z8fpd6f2dmddmqszjardgazg3vrnz4569kwb1yd";
  };
  pkg = pkgs.qt5.mkDerivation rec {
    name = "stremio";

    src = pkgs.fetchgit {
      url = "https://github.com/Stremio/stremio-shell";
      rev = "v${version}";
      sha256 = "116148al678k4b9bm8j7gamvdb00jnvs3z48fgdpdz6a4jyawx9i";
      fetchSubmodules = true;
    };

    nativeBuildInputs = with pkgs; [
      which
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
      qt5.qtdeclarative
      qt5.qtquickcontrols
      qt5.qtquickcontrols2
      qt5.qttools
      qt5.qttranslations
      qt5.qtwebchannel
      qt5.qtwebengine
      wget
    ];

    dontWrapQtApps = true;
    postFixup = ''
      wrapQtApp "$out/opt/stremio/stremio" --prefix PATH : "$out/opt/stremio"
      cp ${serverJS} $out/opt/stremio/server.js
      mkdir $out/bin -p
      ln -s "$out/opt/stremio/stremio" "$out/bin/stremio"
      ln -s "$(which node)" "$out/opt/stremio/node"
    '';
  };
in
pkgs.makeDesktopItem {
  name = "Stremio";
  exec = "${pkg}/bin/stremio %U";
  icon = builtins.fetchurl {
    url = "https://www.stremio.com/website/stremio-logo-small.png";
    sha256 = "15zs8h7f8fsdkpxiqhx7wfw4aadw4a7y190v7kvay0yagsq239l6";
  };
  comment = "Torrent movies and TV series";
  desktopName = "Stremio";
  genericName = "Movies and TV Series";
}
