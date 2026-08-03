# source: https://github.com/sumnerevans/home-manager-config/blob/master/pkgs/mailnotify.nix

{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule rec {
  pname = "mailnotify";
  version = "206290eadf323ce60f6abfd0a6f968af60c0ccca";
  vendorHash = "sha256-8COiuVhQQ8aBDT5/q8Pt6ZTGbB3+xKDlKVA3BsFkF/A=";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = version;
    sha256 = "sha256-3kn6tq3RIS0dYP1XqcuLu2uQWgqb461q759oFfp5HcI=";
  };

  meta = with lib; {
    description = "A small program that notifies when mail has arrived in your mail directory.";
    homepage = "https://github.com/wochap/mailnotify";
    license = licenses.gpl3Plus;
  };
}
