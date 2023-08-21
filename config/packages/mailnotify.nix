# source: https://github.com/sumnerevans/home-manager-config/blob/master/pkgs/mailnotify/default.nix

{ lib, fetchFromGitHub, buildGoPackage, olm }:

buildGoPackage rec {
  pname = "mailnotify";
  version = "0.1.0";

  goPackagePath = "github.com/sumnerevans/mailnotify";
  src = fetchFromGitHub {
    owner = "sumnerevans";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-KPgOtNPK4tE9hzFd7sJwIxRbwh2KFXu/1/m4GT/MBYU=";
  };

  goDeps = ./deps.nix;

  meta = with lib; {
    description =
      "A small program that notifies when mail has arrived in your mail directory.";
    homepage = "https://github.com/sumnerevans/mailnotify";
    license = licenses.gpl3Plus;
  };
}
