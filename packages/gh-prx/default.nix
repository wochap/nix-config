{ lib, fetchFromGitHub, buildGoModule, }:

buildGoModule rec {
  pname = "gh-prx";
  version = "v0.9.0";

  src = fetchFromGitHub {
    owner = "ilaif";
    repo = "gh-prx";
    rev = version;
    hash = "sha256-UYHfhOflP72e6jXk7Sacjg0RNPhPc0H/GpfbEcF8qEo=";
  };

  vendorHash = "sha256-1yT08y/0MONtIkZGzV2MSzoZFLiZ5Kwy79zgDVv0h7Y=";

  meta = {
    description =
      "A GitHub CLI extension to automate the daily work with branches, commits and pull requests.";
    homepage = "https://github.com/ilaif/gh-prx";
    license = lib.licenses.mit;
  };
}
