{
  lib,
  writeShellScriptBin,
  bun,
  agents,
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
writeShellScriptBin "openspec-pipeline" ''
  export AGENTS_CMD=${lib.getExe agents}
  exec ${lib.getExe bun} ${./src}/main.ts "$@"
''
