{ stdenv, glib, fcitx5, fcitx5-gtk, cmake, gnumake, pkg-config, fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "fcitx5-fbterm";
  version = "git";
  src = fetchFromGitHub {
    owner = "fcitx";
    repo = "fcitx5-fbterm";
    rev = "620980bc6dc491448fe22e853b3e1b188996bba1";
    sha256 = "08h538xzfgw05az63px5m41qy9vsbiy3wndpifc12basnr13fwkj";
  };

  nativeBuildInputs = [ cmake gnumake pkg-config ];
  buildInputs = [ fcitx5 fcitx5-gtk glib.dev ];

  installPhase = ''
    mkdir -p $out/bin
    cp src/fcitx5-fbterm $out/bin/
    chmod +x $out/bin/*
  '';
}
