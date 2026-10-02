{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.ai-agents;
  inherit (config._custom.globals) configDirectory;
  # Run from the repo checkout so challenges can be edited without a rebuild.
  llm-bench = pkgs.writeShellScriptBin "llm-bench" ''
    exec ${lib._custom.runtimePath configDirectory ./llm-bench.sh} "$@"
  '';
in
{
  options._custom.programs.ai-agents.llmBench = {
    enable = lib.mkEnableOption { };
  };

  config = lib.mkIf (cfg.enable && cfg.llmBench.enable) {
    environment.systemPackages = [ llm-bench ];
  };
}
