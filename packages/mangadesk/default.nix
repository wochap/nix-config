{ lib, buildGoModule, fetchFromGitHub, makeWrapper, stockfish }:

buildGoModule rec {
  pname = "mangadesk";
  version = "0.7.8";

  src = fetchFromGitHub {
    owner = "darylhjd";
    repo = "mangadesk";
    rev = "v${version}";
    sha256 = "sha256-nfh9X5ULDpUXu/DB9f3jnOsGw9EeMZ+YXwYmAjydCtY=";
  };

  vendorHash = null;

  doCheck = false;

  meta = with lib; {
    description = "The ultimate MangaDex terminal client!";
    homepage = "https://github.com/darylhjd/mangadesk";
    maintainers = with maintainers; [];
    license = licenses.mit;
  };
}
