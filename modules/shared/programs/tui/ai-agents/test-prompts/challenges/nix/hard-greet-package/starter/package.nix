{ stdenvNoCC }:
# TODO: package src/greet.sh (see PROMPT.md)
stdenvNoCC.mkDerivation {
  pname = "greet";
  version = "0.0.0";
  dontUnpack = true;
  installPhase = "mkdir -p $out";
}
