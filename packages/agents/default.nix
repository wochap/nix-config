{
  lib,
  writeShellScriptBin,
  bun,
  dtach,
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
# dtach runs a taken-over session's TUI so Ctrl-Z can detach from it.
writeShellScriptBin "agents" ''
  export AGENTS_DTACH=${lib.getExe dtach}
  exec ${lib.getExe bun} ${./src}/main.ts "$@"
''
