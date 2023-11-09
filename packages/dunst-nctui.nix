{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "dunst-nctui";
  version = "0.1.0-next";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = "43a62f5723fa1669494b927ab1b78107af61a981";
    sha256 = "sha256-7gLbXtuw4wZPSYasiGB0O0jr9hK2BCT28OvvmrvsmpI=";
  };

  vendorHash = "sha256-06zgYVphSC3YoUGEbdNN0jTJTXpLNDykjR41kooJYlE=";

  meta = with lib; {
    description = "Notification center for dunst in the terminal";
    homepage = "https://github.com/wochap/dunst-nctui";
    license = licenses.gpl3Plus;
  };
}

