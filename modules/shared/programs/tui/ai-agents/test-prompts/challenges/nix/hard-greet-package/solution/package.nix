{
  lib,
  stdenvNoCC,
  makeWrapper,
  jq,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "greet";
  version = "1.2.0";

  src = ./src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 greet.sh $out/bin/greet
    wrapProgram $out/bin/greet \
      --prefix PATH : ${lib.makeBinPath [ jq ]} \
      --set GREET_VERSION ${finalAttrs.version}
    runHook postInstall
  '';

  meta = {
    description = "Say hello, optionally as JSON";
    license = lib.licenses.mit;
    mainProgram = "greet";
  };
})
