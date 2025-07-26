# source: https://github.com/sumnerevans/home-manager-config/blob/master/pkgs/mailnotify.nix

{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "mailnotify";
  version = "0.1.0-next";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = "d771510278c63052b7c591e75f451ad38708a970";
    sha256 = "sha256-LDZFQ2YRNQW96MAKsw4H1/uqXrNWDEP0AbBChD9HxJI=";
  };

  vendorHash = "sha256-Mj1vte+bnDmY/tn6+GXX9IwIKgy9J4QvoIP/pLcID6E=";

  meta = with lib; {
    description = "A small program that notifies when mail has arrived in your mail directory.";
    homepage = "https://github.com/sumnerevans/mailnotify";
    license = licenses.gpl3Plus;
  };
}
