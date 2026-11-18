{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  ncfg = cfg.courseNotes;
  inherit (config._custom.globals) configDirectory;
  notesPython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.tiktoken
  ]);
  course-notes = pkgs.writeShellApplication {
    name = "course-notes";
    runtimeInputs = [
      notesPython
    ];
    runtimeEnv = {
      DEFAULT_PROMPT = lib._custom.relativeSymlink configDirectory ./prompt.md;
      COURSE_NOTES_MODEL = if ncfg.model != null then ncfg.model else "desktop-free";
    };
    text = ''
      exec ${notesPython}/bin/python ${./extract_notes.py} "$@"
    '';
  };
  course-notes-dir = pkgs.writeShellApplication {
    name = "course-notes-dir";
    runtimeInputs = [
      course-notes
      pkgs.findutils
      pkgs.gnugrep
      pkgs.coreutils
    ];
    text = builtins.readFile ./course-notes-dir.sh;
  };
in
{
  options._custom.services.ai.courseNotes = {
    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Default OmniRoute model; `--model` overrides it. Null uses
        `desktop-free`.
      '';
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      course-notes
      course-notes-dir
    ];
  };
}
