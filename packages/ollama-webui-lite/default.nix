{ lib, buildNpmPackage, fetchFromGitHub, runtimeShell, nodePackages }:

buildNpmPackage rec {
  pname = "ollama-webui-lite";
  version = "7b3f4bf9767eb3e08f659e45c830e0c5ee4ba34c";

  src = fetchFromGitHub {
    owner = "ollama-webui";
    repo = pname;
    rev = version;
    hash = "sha256-LuELcEtFLOz26TS/QEbzwmy1F8c0Qt19E0DWc11W6s4=";
  };
  npmDepsHash = "sha256-n/MBmt0LG0jHxxilYBWexUBSBgFeU4XeN04xfYVDs+A=";

  PUBLIC_API_BASE_URL = "";
  OLLAMA_API_BASE_URL = "http://localhost:11434/api";

  installPhase = ''
    mkdir -p $out/lib/static
    cp -R ./build/. $out/lib/static

    mkdir -p $out/bin
    cat <<EOF >>$out/bin/${pname}
    #!${runtimeShell}
    ${nodePackages.serve}/bin/serve $out/lib/static --single "\$@"
    EOF
    chmod +x $out/bin/${pname}
  '';

  meta = with lib; {
    description = "Ollama WebUI Stripped 🦙";
    homepage = "https://github.com/ollama-webui/ollama-webui-lite";
    license = licenses.mit;
    mainProgram = pname;
    platforms = platforms.all;
  };
}
