{ lib, buildGoModule, fetchFromGitHub, makeWrapper, stockfish }:

buildGoModule rec {
  pname = "mangadesk";
  version = "0.7.6";

  src = fetchFromGitHub {
    owner = "darylhjd";
    repo = "mangadesk";
    rev = "v${version}";
    sha256 = "sha256-PibG1dmpYP7c03GKgr7nG5bKEoIb9c5til/f8fzvKAk=";
  };

  vendorSha256 = null;

  doCheck = false;

  meta = with lib; {
    description = "The ultimate MangaDex terminal client!";
    homepage = "https://github.com/darylhjd/mangadesk";
    maintainers = with maintainers; [];
    license = licenses.mit;
  };
}
