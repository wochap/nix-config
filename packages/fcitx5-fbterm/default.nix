{ stdenv, glib, fcitx5, fcitx5-gtk, cmake, gnumake, pkg-config, fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "fcitx5-fbterm";
  version = "git";
  src = fetchFromGitHub {
    owner = "fcitx";
    repo = "fcitx5-fbterm";
    rev = "6067ed2d573a0f5a24dc43e7fad0beb72104446b";
    sha256 = "sha256-kVwGkBP0Ttu1QsSjLWEbLhuUmelkGlzdAsQi4J4VS08=";
  };

  nativeBuildInputs = [ cmake gnumake pkg-config ];
  buildInputs = [ fcitx5 fcitx5-gtk glib.dev ];

  installPhase = ''
    mkdir -p $out/bin
    cp src/fcitx5-fbterm $out/bin/
    chmod +x $out/bin/*
  '';
}
