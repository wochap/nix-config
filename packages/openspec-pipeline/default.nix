{
  lib,
  writeShellScriptBin,
  symlinkJoin,
  bun,
  agenttap,
  defaultPreset ? "agy",
}:

# TypeScript run directly by Bun; no dependencies, so no package.json.
symlinkJoin {
  name = "openspec-pipeline";
  paths = [
    (writeShellScriptBin "openspec-pipeline" ''
      export AGENTTAP_CMD=${lib.getExe agenttap}
      export OPENSPEC_PIPELINE_PRESET=''${OPENSPEC_PIPELINE_PRESET:-${defaultPreset}}
      exec ${lib.getExe bun} ${./src}/main.ts "$@"
    '')
  ];
  postBuild = ''
    install -Dm444 ${./completions/_openspec-pipeline} $out/share/zsh/site-functions/_openspec-pipeline
  '';
  meta.mainProgram = "openspec-pipeline";
}
