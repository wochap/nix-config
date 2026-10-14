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
    agents = "claude/claude-sonnet-5-5";
    agents-server = "claude/claude-sonnet-5-5";
    omniroute = "desktop-free";
  };
  course-notes = pkgs.writeShellApplication {
    name = "course-notes";
    runtimeInputs = [
      notesPython
    ]
    ++ lib.optional (ncfg.backend == "agents") pkgs._custom.agents;
    runtimeEnv = {
      DEFAULT_PROMPT = lib._custom.relativeSymlink configDirectory ./prompt.md;
      COURSE_NOTES_BACKEND = ncfg.backend;
      COURSE_NOTES_MODEL = if ncfg.model != null then ncfg.model else defaultModels.${ncfg.backend};
    }
    // lib.optionalAttrs (ncfg.backend == "agents-server") {
      AGENTS_SERVER_URL = "http://${wochap-ssc.meta.address}:${toString config._custom.services.web-gate.proxies.agents-server.publicPort}/v1";
      AGENTS_SERVER_API_KEY_FILE = config.sops.secrets.agents-server-api-key.path;
    };
    text = ''
      exec ${notesPython}/bin/python ${./extract_notes.py} "$@"
    '';
  };
in
{
  options._custom.services.ai.courseNotes = {
    backend = lib.mkOption {
      type = lib.types.enum [
        "agents"
        "agents-server"
        "omniroute"
      ];
      default = "omniroute";
      description = ''
        Where the notes are generated: the agents CLI run directly
        (`agents run --no-tools`), the agents-server OpenAI-compatible API,
        or OmniRoute through `omniroute-chat`.
      '';
    };
    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Default model; `--model` overrides it. Null picks the backend's
        default: `claude/claude-sonnet-5-5` (`<agent>/<model>`) for agents and
        agents-server, `desktop-free` for omniroute.
      '';
    };
  };

  config = lib.mkIf (cfg.enable) {
    assertions = [
      {
        assertion = ncfg.backend != "agents-server" || cfg.agentsServer.enable;
        message = "_custom.services.ai.courseNotes.backend = \"agents-server\" needs _custom.services.ai.agentsServer.enable.";
      }
    ];

    environment.systemPackages = [ course-notes ];
  };
}
