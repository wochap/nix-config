{ lib, buildGoModule, fetchFromGitHub, makeWrapper, stockfish }:

buildGoModule rec {
  pname = "mangadesk";
  version = "592a08c8914eb60f11618af0fd08bd94d4828850";

  src = fetchFromGitHub {
    owner = "darylhjd";
    repo = "mangadesk";
    rev = "v${version}";
    sha256 = "sha256-axVwQOVG4KLcL2IpuILBifaJYhvkwQ0B8373E338NgM=";
  };

  vendorHash = "sha256-5hHTTI+RRqUoG3x1WCRUyA0WM4rYltJuxwWiIa3DHk8=";

  doCheck = false;

  meta = with lib; {
    description = "The ultimate MangaDex terminal client!";
    homepage = "https://github.com/darylhjd/mangadesk";
    maintainers = with maintainers; [ ];
    license = licenses.mit;
  };
}
