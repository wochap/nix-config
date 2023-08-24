# source: https://github.com/sumnerevans/home-manager-config/blob/master/pkgs/mailnotify.nix

{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "mailnotify";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "sumnerevans";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-KPgOtNPK4tE9hzFd7sJwIxRbwh2KFXu/1/m4GT/MBYU=";
  };

  vendorHash = "sha256-Mj1vte+bnDmY/tn6+GXX9IwIKgy9J4QvoIP/pLcID6E=";

  meta = with lib; {
    description = "A small program that notifies when mail has arrived in your mail directory.";
    homepage = "https://github.com/sumnerevans/mailnotify";
    license = licenses.gpl3Plus;
  };
}
