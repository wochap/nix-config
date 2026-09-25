{
  lib,
  writeShellScriptBin,
  symlinkJoin,
  bun,
  agents,
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
symlinkJoin {
  name = "openspec-pipeline";
  paths = [
    (writeShellScriptBin "openspec-pipeline" ''
      export AGENTS_CMD=${lib.getExe agents}
      exec ${lib.getExe bun} ${./src}/main.ts "$@"
    '')
  ];
  postBuild = ''
    install -Dm444 ${./completions/_openspec-pipeline} $out/share/zsh/site-functions/_openspec-pipeline
  '';
  meta.mainProgram = "openspec-pipeline";
}
