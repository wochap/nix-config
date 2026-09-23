{
  lib,
  writeShellScriptBin,
  bun,
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
writeShellScriptBin "openspec-pipeline" ''
  exec ${lib.getExe bun} ${./src}/main.ts "$@"
''
