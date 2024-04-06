{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "dunst-nctui";
  version = "v0.2.0";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = version;
    sha256 = "sha256-B6CVPSJVQT48YIOwxN9L2hu0DcTuUgVxeIe2vkdRJCg=";
  };

  vendorHash = "sha256-06zgYVphSC3YoUGEbdNN0jTJTXpLNDykjR41kooJYlE=";

  meta = with lib; {
    description = "Notification center for dunst in the terminal";
    homepage = "https://github.com/wochap/dunst-nctui";
    license = licenses.gpl3Plus;
  };
}

