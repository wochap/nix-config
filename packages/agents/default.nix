{
  lib,
  writeShellScriptBin,
  symlinkJoin,
  bun,
  dtach,
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
# dtach runs a taken-over session's TUI so Ctrl-Z can detach from it.
symlinkJoin {
  name = "agents";
  paths = [
    (writeShellScriptBin "agents" ''
      export AGENTS_DTACH=${lib.getExe dtach}
      exec ${lib.getExe bun} ${./src}/main.ts "$@"
    '')
  ];
  postBuild = ''
    install -Dm444 ${./completions/_agents} $out/share/zsh/site-functions/_agents
  '';
  meta.mainProgram = "agents";
}
