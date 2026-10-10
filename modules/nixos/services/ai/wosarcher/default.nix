{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  wcfg = cfg.wosarcher;
  inherit (pkgs._custom) wochap-ssc;
  toml = pkgs.formats.toml { };
  # Total context window and largest completion per model (../model-presets.nix).
  models = import ../model-presets.nix { inherit lib; };

  # The unit services.wosarcher defines.
  serviceName = "wosarcher";
  # The uid and gid the former container image ran as, so the files already
  # in /var/lib/wosarcher keep their owner.
  uid = 10001;
  gid = 10001;

  proxy = config._custom.services.web-gate.proxies.wosarcher;
  # Secret files the daemon reads itself (`<x>_file` settings). The profiles
  # hold paths, never values, so they are safe in the Nix store.
  omnirouteKeyFile = config.sops.secrets.wosarcher-omniroute-api-key.path;
  agentsKeyFile = config.sops.secrets.wosarcher-agents-api-key.path;
  jevKeyFile = config.sops.secrets.wosarcher-typesafe-api-key.path;
  searxProxy = config._custom.services.web-gate.proxies.searxng;
  omniRouteProxy = config._custom.services.web-gate.proxies.omniroute;
  firecrawlPublicPort = lib.attrByPath [
    "firecrawl"
    "publicPort"
  ] 20900 config._custom.services.web-gate.proxies;
  rerankerProxy = config._custom.services.web-gate.proxies.reranker;
  host = "http://${wochap-ssc.meta.address}";

  # The OpenAI-compatible servers an entry of `llms` can call.
  endpoints = {
    omniroute = {
      base_url = "${host}:${toString omniRouteProxy.publicPort}/v1";
      api_key_file = omnirouteKeyFile;
    };
    # agents serve (../agents-server): Claude Code and pi without tools; the
    # request's system message replaces the agent's own system prompt.
    agents = {
      base_url = "${host}:${toString config._custom.services.web-gate.proxies.agents-server.publicPort}/v1";
      api_key_file = agentsKeyFile;
    };
  };
  usesAgents = lib.any (llm: llm.endpoint == "agents") (lib.attrValues wcfg.llms);

  # Every provider goes through the host's proxies. The reranker is reached
  # through its lazy socket proxy: the first rerank starts llama-server again
  # after the idle watchdog stopped it.
  commonProfile = {
    run.gpu_policy = "shared";
    search = {
      provider = "searxng";
      base_url = "${host}:${toString searxProxy.publicPort}";
    };
    fetch = {
      provider = "firecrawl";
      base_url = "${host}:${toString firecrawlPublicPort}/v1";
    };
  };

  # The llm and research blocks for one entry of `llms`. context_window is the
  # model's total window (prompt plus completion): wosarcher subtracts the
  # prompt reserve and the output allowance itself to size the passages. As in
  # gpt-researcher, a completion never claims more than half the window.
  llmSettings =
    llm:
    let
      m = models.resolve "wosarcher" llm.preset;
    in
    {
      llm = {
        provider = "openai";
        inherit (endpoints.${llm.endpoint}) base_url api_key_file;
        inherit (llm) model timeout;
        context_window = m.contextTokens;
        max_output_tokens = lib.min models.maxOutputCap (lib.min m.maxOutputTokens (m.contextTokens / 2));
      }
      // lib.optionalAttrs (llm.reasoning != { }) { inherit (llm) reasoning; };
    }
    // lib.optionalAttrs (llm.research != { }) { inherit (llm) research; };

  embeddingsPrefilter = {
    provider = "embeddings";
    base_url = "http://127.0.0.1:11434/v1";
    model = cfg.ollamaEmbeddingModel;
    device = "local:gpu0";
  };

  # Without the shared reranker this falls back to BM25 scoring.
  rerankScore =
    if cfg.reranker.enable then
      {
        provider = "rerank";
        base_url = "${host}:${toString rerankerProxy.publicPort}/v1";
        model = cfg.reranker.model;
        device = "local:gpu0";
        # Covers llama-server loading the GGUF on the first request.
        timeout = 120;
      }
    else
      { provider = "bm25"; };

  # TypeSafe Jev: a cloud scorer with calibrated 0-3 usefulness scores. It
  # sends every chunk to api.typesafe.ai and needs an API key. In a replay of
  # 9 questions it was judged at least as precise as the local reranker, with
  # a 2-4 s score stage instead of 26-40 s on the GPU.
  jevScore = {
    provider = "jev";
    base_url = "https://api.typesafe.ai/v1";
    api_key_file = jevKeyFile;
    concurrency = 16;
    timeout = 120;
  };

  # How passages are picked; each is paired with every entry of `llms`.
  scorerVariants = {
    embeddings-rerank = commonProfile // {
      prefilter = embeddingsPrefilter;
      score = rerankScore;
    };
  }
  // lib.optionalAttrs wcfg.jev.enable {
    embeddings-jev = commonProfile // {
      prefilter = embeddingsPrefilter;
      score = jevScore;
    };
    # No embedding step: BM25 picks the candidates Jev scores.
    bm25-jev = commonProfile // {
      prefilter.provider = "bm25";
      score = jevScore;
    };
    # Coverage over speed (not yet evaluated): Jev scores twice the
    # candidates, keeps only "partly answers" (2.0 of 3) and above, and up to
    # 25 per sub-query, which fills more of the writer's context budget. Depth
    # presets set score.top_k themselves and win over a profile, so use it
    # with Standard depth and add rounds per run (--rounds 3, or Rounds in the
    # web's Custom depth with Passages per query 25).
    bm25-jev-wide = commonProfile // {
      prefilter = {
        provider = "bm25";
        top_k = 100;
      };
      score = jevScore // {
        min_score = 2.0;
        top_k = 25;
      };
    };
  };

  # Every scorer variant once per LLM: the `defaultLlm` keeps the plain
  # variant name (so WOSARCHER_PROFILE values keep working), every other LLM
  # gets a "-<llm>" suffix, for example bm25-jev-free.
  generatedProfiles = lib.concatMapAttrs (
    llmName: llm:
    lib.mapAttrs' (
      variant: settings:
      lib.nameValuePair (if llmName == wcfg.defaultLlm then variant else "${variant}-${llmName}") (
        settings // llmSettings llm
      )
    ) scorerVariants
  ) wcfg.llms;

in
{
  imports = [ inputs.wosarcher.nixosModules.default ];

  options._custom.services.ai.wosarcher = {
    enable = lib.mkEnableOption "the wosarcher research server";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "embeddings-rerank";
      description = "Profile selected through WOSARCHER_PROFILE.";
    };

    llms = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            endpoint = lib.mkOption {
              type = lib.types.enum (lib.attrNames endpoints);
              default = "omniroute";
              description = ''
                Server the profile's llm block calls: omniroute, or agents
                (agents serve; needs agentsServer with tools off).
              '';
            };
            model = lib.mkOption {
              type = lib.types.str;
              description = ''
                Model the endpoint serves: an OmniRoute model or combo, or an
                agents <agent>/<model> id such as claude/claude-sonnet-5-5.
              '';
            };
            preset = lib.mkOption {
              type = models.type;
              description = ''
                Limits of the model behind the combo: a preset name
                (${models.names}) or { contextTokens; maxOutputTokens; }. For a
                combo that falls back between models, use its smallest member.
              '';
            };
            timeout = lib.mkOption {
              type = lib.types.number;
              default = 300;
              description = "Seconds wosarcher waits for one LLM response.";
            };
            research = lib.mkOption {
              type = toml.type;
              default = { };
              description = "Keys of the profile's research block, such as gap_context_tokens.";
            };
            reasoning = lib.mkOption {
              type = toml.type;
              default = { };
              description = ''
                Thinking effort per LLM step (plan, gap, write): none, low,
                medium, high, or default. Empty keeps wosarcher's default, none.
              '';
            };
          };
        }
      );
      description = ''
        LLMs the generated profiles are built for. Every generated profile
        exists once per entry: the defaultLlm entry keeps the plain profile
        name, every other entry adds a "-<name>" suffix.
      '';
    };

    defaultLlm = lib.mkOption {
      type = lib.types.str;
      default = "deepseek";
      description = "Entry of llms used by the generated profiles without a suffix.";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf toml.type;
      default = { };
      description = ''
        Profiles passed to services.wosarcher.profiles, which copies them to
        /var/lib/wosarcher/config/wosarcher/profiles/<name>.toml.
        The generated profiles (embeddings-rerank, and with jev.enable
        embeddings-jev, bm25-jev and bm25-jev-wide, each once per entry of
        llms) are wired to this host's SearxNG,
        Firecrawl, Ollama, OmniRoute or agents serve and, when enabled, the
        shared reranker;
        each of their keys can be overridden. Never put secret values here:
        they land in the Nix store. Point a `<x>_file` setting (for example
        llm.api_key_file) at a SOPS secret owned by the wosarcher user.
      '';
    };

    jev.enable = lib.mkEnableOption ''
      the TypeSafe Jev scorer: adds the embeddings-jev and bm25-jev profiles,
      whose score block reads personal-typesafe-api-key from
      secrets-sops/personal.yaml through score.api_key_file
    '';

    passwordHashSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "wosarcher-password-hash";
      description = ''
        Name of a sops secret holding the admin password's scrypt hash (from
        `wosarcherd auth set-password --print`), passed to the daemon as
        auth.password_hash_file. Null keeps the hash the daemon stores itself
        with `sudo -u wosarcher wosarcherd auth set-password`.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Extra WOSARCHER_* variables for the service, for example
        WOSARCHER_SERVER__LOG_LEVEL. systemd reads it as root; nothing else
        does. Secrets go through `<x>_file` settings instead (see
        passwordHashSecret).
      '';
    };
  };

  config = lib.mkIf (cfg.enable && wcfg.enable) {
    _custom.services.ai.wosarcher.llms = {
      # OmniRoute's research-smart combo: DeepSeek V4 Flash, 1M context.
      deepseek = {
        model = lib.mkDefault "research-smart";
        preset = lib.mkDefault "deepseek-v4-flash";
        timeout = lib.mkDefault 300;
        # The gap step reads the best passages so far; "auto" gives it all the
        # room the 1M window leaves instead of wosarcher's 4000-token default.
        research.gap_context_tokens = lib.mkDefault "auto";
        # Measured on one run: low thinking at write time lifted citation
        # faithfulness from 0.52 to 0.64 with the same passages.
        reasoning.write = lib.mkDefault "low";
      };
      # OmniRoute's desktop-free combo (free Gemma 4 31B, then Ollama Cloud,
      # then the local gdesktop-qwen3.5:9b). The combo can fall back to the
      # local 32k model, so size for the smallest member.
      free = {
        model = lib.mkDefault "desktop-free";
        preset = lib.mkDefault "qwen3-5-9b-local";
        # Prompt processing of a large context on the local GPU is slow.
        timeout = lib.mkDefault 600;
        research.gap_context_tokens = lib.mkDefault 4000;
      };
      # Claude through agents serve. Effort "none" (the write default) keeps
      # Claude Code's own effort: high for Sonnet, medium for Haiku.
      sonnet = lib.mkIf cfg.agentsServer.enable {
        endpoint = lib.mkDefault "agents";
        model = lib.mkDefault "claude/claude-sonnet-5-5";
        preset = lib.mkDefault "claude-sonnet-5-5";
        timeout = lib.mkDefault 900;
        reasoning.plan = lib.mkDefault "low";
        reasoning.gap = lib.mkDefault "low";
      };
      haiku = lib.mkIf cfg.agentsServer.enable {
        endpoint = lib.mkDefault "agents";
        model = lib.mkDefault "claude/claude-haiku-5-5";
        preset = lib.mkDefault "claude-haiku-5-5";
        timeout = lib.mkDefault 600;
        reasoning.plan = lib.mkDefault "low";
        reasoning.gap = lib.mkDefault "low";
      };
    };

    # The llm prompts carry scraped web text; with tools an agent could act
    # on instructions planted in it.
    assertions = [
      {
        assertion = !usesAgents || (cfg.agentsServer.enable && !cfg.agentsServer.tools);
        message = "wosarcher: an llms entry with endpoint = \"agents\" needs agentsServer enabled with tools = false";
      }
    ];

    _custom.services.ai.wosarcher.profiles = lib.mapAttrs (
      _: lib.mapAttrsRecursive (_: lib.mkDefault)
    ) generatedProfiles;

    _custom.services.web-gate.proxies.wosarcher = {
      enable = true;
      subdomain = "wosarcher";
      inherit serviceName;
      publicPort = 20600;
      backendPort = 20601;
      lazy = true;
    };

    services.wosarcher = {
      enable = true;
      host = wochap-ssc.meta.address;
      port = proxy.backendPort;
      # The web-gate socket starts the unit on the first request.
      autoStart = false;
      users = [ config._custom.globals.userName ];
      # The browser's Origin is the nginx virtual host, not the backend
      # address, so state-changing requests need it allowed explicitly.
      allowedOrigins = [
        "https://${proxy.subdomain}.${wochap-ssc.meta.domain}"
      ]
      ++ lib.optional proxy.expose.enable "https://${proxy.expose.host}";
      environment = {
        WOSARCHER_PROFILE = wcfg.profile;
      }
      // lib.optionalAttrs (wcfg.passwordHashSecret != null) {
        WOSARCHER_AUTH__PASSWORD_HASH_FILE = config.sops.secrets.${wcfg.passwordHashSecret}.path;
      };
      environmentFile = wcfg.environmentFile;
      inherit (wcfg) profiles;
    };

    users.users.wosarcher.uid = uid;
    users.groups.wosarcher.gid = gid;

    # Copies of the keys owned by the service user: the daemon reads them
    # itself when a run resolves its profile, so a rotated key reaches the
    # next run without a restart, and no other user can read them. Group
    # members only reach the daemon's socket.
    sops.secrets.wosarcher-omniroute-api-key = {
      sopsFile = ../../../../../secrets-sops/local.yaml;
      key = "local-omniroute-secret-key";
      owner = "wosarcher";
      group = "wosarcher";
      mode = "0400";
    };
    sops.secrets.wosarcher-agents-api-key = lib.mkIf usesAgents {
      sopsFile = ../../../../../secrets-sops/local.yaml;
      key = "local-agents-server-api-key";
      owner = "wosarcher";
      group = "wosarcher";
      mode = "0400";
    };
    sops.secrets.wosarcher-typesafe-api-key = lib.mkIf wcfg.jev.enable {
      sopsFile = ../../../../../secrets-sops/personal.yaml;
      key = "personal-typesafe-api-key";
      owner = "wosarcher";
      group = "wosarcher";
      mode = "0400";
    };

    systemd.services.${serviceName} = {
      requires = [ "ollama.service" ];
      after = [ "ollama.service" ];
    };
  };
}
