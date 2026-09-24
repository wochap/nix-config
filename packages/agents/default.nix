{
  lib,
  writeShellScriptBin,
  bun,
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
writeShellScriptBin "agents" ''
  exec ${lib.getExe bun} ${./src}/main.ts "$@"
''
