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
  inherit (pkgs._custom) wochap-ssc;
  notesPython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.tiktoken
  ]);
  defaultModels = {
    agenttap = "claude/claude-sonnet-5-5";
    agenttap-server = "claude/claude-sonnet-5-5";
    omniroute = "desktop-free";
  };
  course-notes = pkgs.writeShellApplication {
    name = "course-notes";
    runtimeInputs = [
      notesPython
    ]
    ++ lib.optional (ncfg.backend == "agenttap") pkgs._custom.agenttap;
    runtimeEnv = {
      DEFAULT_PROMPT = lib._custom.relativeSymlink configDirectory ./prompt.md;
      COURSE_NOTES_BACKEND = ncfg.backend;
      COURSE_NOTES_MODEL = if ncfg.model != null then ncfg.model else defaultModels.${ncfg.backend};
    }
    // lib.optionalAttrs (ncfg.backend == "agenttap-server") {
      AGENTTAP_SERVER_URL = "http://${wochap-ssc.meta.address}:${toString config._custom.services.web-gate.proxies.agenttap-server.publicPort}/v1";
      AGENTTAP_SERVER_API_KEY_FILE = config.sops.secrets.agenttap-server-api-key.path;
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
    backend = lib.mkOption {
      type = lib.types.enum [
        "agenttap"
        "agenttap-server"
        "omniroute"
      ];
      default = "omniroute";
      description = ''
        Where the notes are generated: the agenttap CLI run directly
        (`agenttap run --no-tools`), the agenttap-server OpenAI-compatible API,
        or OmniRoute through `omniroute-chat`.
      '';
    };
    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Default model; `--model` overrides it. Null picks the backend's
        default: `claude/claude-sonnet-5-5` (`<agent>/<model>`) for agenttap and
        agenttap-server, `desktop-free` for omniroute.
      '';
    };
  };

  config = lib.mkIf (cfg.enable) {
    assertions = [
      {
        assertion = ncfg.backend != "agenttap-server" || cfg.agenttapServer.enable;
        message = "_custom.services.ai.courseNotes.backend = \"agenttap-server\" needs _custom.services.ai.agenttapServer.enable.";
      }
    ];

    environment.systemPackages = [
      course-notes
      course-notes-dir
    ];
  };
}
