{
  lib,
  writeShellScriptBin,
  symlinkJoin,
  bun,
  dtach,
  bubblewrap,
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
# dtach runs a taken-over session's TUI so Ctrl-Z can detach from it.
# bubblewrap provides sandbox isolation for agenttap and agenttap-sandbox.
symlinkJoin {
  name = "agenttap";
  paths = [
    (writeShellScriptBin "agenttap" ''
      export AGENTTAP_DTACH=${lib.getExe dtach}
      export PATH="${lib.makeBinPath [ bubblewrap ]}:$PATH"
      exec ${lib.getExe bun} ${./src}/main.ts "$@"
    '')
    (writeShellScriptBin "agenttap-sandbox" ''
      export PATH="${lib.makeBinPath [ bubblewrap ]}:$PATH"
      exec ${lib.getExe bun} ${./src}/sandbox-cli.ts "$@"
    '')
  ];
  postBuild = ''
    install -Dm444 ${./completions/_agenttap} $out/share/zsh/site-functions/_agenttap
  '';
  meta.mainProgram = "agenttap";
}
