# source: https://github.com/sumnerevans/home-manager-config/blob/master/pkgs/mailnotify.nix

{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule rec {
  pname = "mailnotify";
  version = "ac66c4a4bad09dfdb55d6dd9543035f780d031af";
  vendorHash = "sha256-8COiuVhQQ8aBDT5/q8Pt6ZTGbB3+xKDlKVA3BsFkF/A=";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = version;
    sha256 = "sha256-PQdQBCWtqD0Czg+vTv43dGskXCr2uubJXwuo6TZwdhk=";
  };

  meta = with lib; {
    description = "A small program that notifies when mail has arrived in your mail directory.";
    homepage = "https://github.com/wochap/mailnotify";
    license = licenses.gpl3Plus;
  };
}
