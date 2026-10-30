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
# bubblewrap provides sandbox isolation for agents and agents-sandbox.
symlinkJoin {
  name = "agents";
  paths = [
    (writeShellScriptBin "agents" ''
      export AGENTS_DTACH=${lib.getExe dtach}
      export PATH="${lib.makeBinPath [ bubblewrap ]}:$PATH"
      exec ${lib.getExe bun} ${./src}/main.ts "$@"
    '')
    (writeShellScriptBin "agents-sandbox" ''
      export PATH="${lib.makeBinPath [ bubblewrap ]}:$PATH"
      exec ${lib.getExe bun} ${./src}/sandbox-cli.ts "$@"
    '')
  ];
  postBuild = ''
    install -Dm444 ${./completions/_agents} $out/share/zsh/site-functions/_agents
  '';
  meta.mainProgram = "agents";
}
