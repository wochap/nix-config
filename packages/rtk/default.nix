{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "rtk";
  version = "0.45.0";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    tag = "v${version}";
    hash = "sha256-weAyHM0nWLrM8JRbbXIfjUsHtAep3DOFyTO+M3BZ/iU=";
  };

  cargoHash = "sha256-tgW6il/xLxt/xwhUBJ4MNVnk0JSZ7iFjJaEobj5+H4o=";

  # Several tests require writable user state and external commands unavailable
  # in the isolated Nix build environment.
  doCheck = false;

  meta = {
    description = "High-performance CLI proxy to minimize LLM token consumption";
    homepage = "https://www.rtk-ai.app";
    license = lib.licenses.asl20;
    mainProgram = "rtk";
    platforms = lib.platforms.unix;
  };
}
