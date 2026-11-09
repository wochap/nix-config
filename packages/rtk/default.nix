{
  lib,
  inputs,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "rtk";
  version = inputs.rtk.shortRev or "dirty";

  src = inputs.rtk;

  # cargoHash = lib.fakeHash;
  cargoHash = "sha256-0VUc3Se3MdmffCkbCw2esLnmht9ZhwnmVCqxjudElfA=";

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
