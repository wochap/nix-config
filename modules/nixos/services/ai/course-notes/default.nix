{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (config._custom.globals) configDirectory;
  notesPython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.tiktoken
  ]);
  course-notes = pkgs.writeShellApplication {
    name = "course-notes";
    runtimeInputs = with pkgs; [
      notesPython
    ];
    runtimeEnv = {
      DEFAULT_PROMPT = lib._custom.relativeSymlink configDirectory ./prompt.md;
    };
    text = ''
      exec ${notesPython}/bin/python ${./extract_notes.py} "$@"
    '';
  };
in
{
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ course-notes ];
  };
}
