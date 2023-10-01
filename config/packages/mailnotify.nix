# source: https://github.com/sumnerevans/home-manager-config/blob/master/pkgs/mailnotify.nix

{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "mailnotify";
  version = "0.1.0-next";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = "56b719d2c5a072121001ab90dfb993da2c486e38";
    sha256 = "sha256-7ikjr49tznr/QbbBJYaQYfHGWQe9eNrzP7di7nKdKUw=";
  };

  vendorHash = "sha256-Mj1vte+bnDmY/tn6+GXX9IwIKgy9J4QvoIP/pLcID6E=";

  meta = with lib; {
    description = "A small program that notifies when mail has arrived in your mail directory.";
    homepage = "https://github.com/sumnerevans/mailnotify";
    license = licenses.gpl3Plus;
  };
}
