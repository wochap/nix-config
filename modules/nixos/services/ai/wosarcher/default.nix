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
  hashSecret = wcfg.passwordHashSecret;
  inherit (pkgs._custom) wochap-ssc;
  toml = pkgs.formats.toml { };
  # Total context window and largest completion per model (../model-presets.nix).
  presets = import ../model-presets.nix { inherit lib; };

  # The unit services.wosarcher defines.
  serviceName = "wosarcher";
  # The uid and gid the former container image ran as, so the files already
  # in /var/lib/wosarcher keep their owner.
  uid = 10001;
  gid = 10001;

  proxy = config._custom.services.web-gate.proxies.wosarcher;
  # Secret files the daemon reads itself (`<x>_file` settings). Entries hold
  # paths, never values, so they are safe in the Nix store.
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

  # The OpenAI-compatible servers a model can be served by. Each one with at
  # least one entry in `models` becomes an llm entry of the same name.
  endpoints = {
    omniroute = {
      description = "OmniRoute on this host's proxy.";
      base_url = "${host}:${toString omniRouteProxy.publicPort}/v1";
      api_key_file = omnirouteKeyFile;
    };
    # agents serve (../agents-server): Claude Code and pi without tools; the
    # request's system message replaces the agent's own system prompt.
    agents = {
      description = "agents serve: Claude Code and pi without tools.";
      base_url = "${host}:${toString config._custom.services.web-gate.proxies.agents-server.publicPort}/v1";
      api_key_file = agentsKeyFile;
    };
  };
  modelsOf = endpoint: lib.filterAttrs (_: m: m.endpoint == endpoint) wcfg.models;
  usedEndpoints = lib.filterAttrs (name: _: modelsOf name != { }) endpoints;
  usesAgents = usedEndpoints ? agents;

  # One `models.<id>` table. context_window is the model's total window
  # (prompt plus completion): wosarcher subtracts the prompt reserve and the
  # output allowance itself to size the passages. As in gpt-researcher, a
  # completion never claims more than half the window.
  modelTable =
    m:
    let
      limits = presets.resolve "wosarcher" m.preset;
    in
    {
      context_window = limits.contextTokens;
      max_output_tokens = lib.min presets.maxOutputCap (
        lib.min limits.maxOutputTokens (limits.contextTokens / 2)
      );
    }
    // lib.optionalAttrs (m.reasoning != { }) { inherit (m) reasoning; }
    // lib.optionalAttrs (m.gapContextTokens != null) { gap_context_tokens = m.gapContextTokens; };

  llmEntries = lib.mapAttrs (name: endpoint: {
    provider = "openai";
    inherit (endpoint) description base_url api_key_file;
    inherit (wcfg.endpoints.${name}) model timeout;
    models = lib.mapAttrs (_: modelTable) (modelsOf name);
  }) usedEndpoints;

  # TypeSafe Jev: a cloud scorer with calibrated 0-3 usefulness scores. It
  # sends every chunk to api.typesafe.ai and needs an API key. In a replay of
  # 9 questions it was judged at least as precise as the local reranker, with
  # a 2-4 s score stage instead of 26-40 s on the GPU.
  jevScore = {
    description = "TypeSafe Jev; 50 candidates per query.";
    provider = "jev";
    base_url = "https://api.typesafe.ai/v1";
    api_key_file = jevKeyFile;
    concurrency = 16;
    timeout = 120;
  };

  # Every provider goes through the host's proxies. The reranker is reached
  # through its lazy socket proxy: the first rerank starts llama-server again
  # after the idle watchdog stopped it. Without the reranker, profiles score
  # with the built-in bm25 entry.
  generatedProviders = {
    search.searxng = {
      description = "SearXNG on this host.";
      provider = "searxng";
      base_url = "${host}:${toString searxProxy.publicPort}";
    };
    fetch.firecrawl = {
      description = "Firecrawl on this host.";
      provider = "firecrawl";
      base_url = "${host}:${toString firecrawlPublicPort}/v1";
    };
    prefilter.embeddings = {
      description = "Ollama embeddings on the local GPU.";
      provider = "embeddings";
      base_url = "http://127.0.0.1:11434/v1";
      model = cfg.ollamaEmbeddingModel;
      device = "local:gpu0";
    };
    score =
      lib.optionalAttrs cfg.reranker.enable {
        rerank = {
          description = "Shared llama-server reranker on the local GPU.";
          provider = "rerank";
          base_url = "${host}:${toString rerankerProxy.publicPort}/v1";
          model = cfg.reranker.model;
          device = "local:gpu0";
          # Covers llama-server loading the GGUF on the first request.
          timeout = 120;
        };
      }
      // lib.optionalAttrs wcfg.jev.enable {
        jev = jevScore;
        # Jev scores twice the candidates and keeps "partly answers" (2.0 of
        # 3) and above. Pair it with the `wide` depth for coverage.
        jev-strict = jevScore // {
          description = "TypeSafe Jev; 100 candidates, keeps partial answers and better.";
          candidates = 100;
          min_score = 2.0;
        };
      };
    llm = llmEntries;
  };

  baseProfile = {
    run.gpu_policy = "shared";
  };
  use = {
    search = "searxng";
    fetch = "firecrawl";
    prefilter = "embeddings";
    score = if cfg.reranker.enable then "rerank" else "bm25";
    llm = "omniroute";
  };
  generatedProfiles = {
    default = baseProfile // {
      description = "SearXNG, Firecrawl, embeddings, ${use.score} scoring, OmniRoute.";
      inherit use;
    };
  }
  // lib.optionalAttrs wcfg.jev.enable {
    jev = baseProfile // {
      description = "SearXNG, Firecrawl, embeddings, Jev (strict) scoring, OmniRoute.";
      use = use // {
        score = "jev-strict";
      };
    };
    quick = baseProfile // {
      description = "SearXNG, Firecrawl, bm25 prefilter, Jev (strict) scoring, OmniRoute.";
      use = use // {
        prefilter = "bm25";
        score = "jev";
      };
    };
  };

  # Coverage over speed: up to 25 passages per sub-query, which fills more of
  # the writer's context budget, and three research rounds that follow up on
  # gaps. The other depth keys keep the standard values.
  generatedDepths.wide = {
    description = "Broad coverage: 25 passages per query, three rounds.";
    score.top_k = 25;
    research.rounds = 3;
  };

  # Every leaf a default, so a host can override single keys.
  defaults = lib.mapAttrsRecursive (_: lib.mkDefault);

  endpointOption =
    name: model: timeout:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          model = lib.mkOption {
            type = lib.types.str;
            default = model;
            description = "Default model of the ${name} llm entry; list it in `models`.";
          };
          timeout = lib.mkOption {
            type = lib.types.number;
            default = timeout;
            description = "Seconds wosarcher waits for one response from ${name}.";
          };
        };
      };
      default = { };
      description = "Settings of the ${name} llm entry.";
    };
in
{
  imports = [ inputs.wosarcher.nixosModules.default ];

  options._custom.services.ai.wosarcher = {
    enable = lib.mkEnableOption "the wosarcher research server";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = ''
        Profile selected through WOSARCHER_PROFILE: default, jev and quick
        (with jev.enable), or a name from `profiles`.
      '';
    };

    endpoints = {
      omniroute = endpointOption "omniroute" "research-smart" 600;
      agents = endpointOption "agents" "claude/claude-sonnet-5-5" 900;
    };

    models = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            endpoint = lib.mkOption {
              type = lib.types.enum (lib.attrNames endpoints);
              default = "omniroute";
              description = ''
                llm entry that serves the model: omniroute, or agents (agents
                serve; needs agentsServer with tools off).
              '';
            };
            preset = lib.mkOption {
              type = presets.type;
              description = ''
                Limits of the model behind the id: a preset name
                (${presets.names}) or { contextTokens; maxOutputTokens; }. For
                a combo that falls back between models, use its smallest member.
              '';
            };
            reasoning = lib.mkOption {
              type = toml.type;
              default = { };
              description = ''
                Thinking effort per LLM step (plan, gap, write): none, low,
                medium, high, or default. Empty keeps wosarcher's default, none.
              '';
            };
            gapContextTokens = lib.mkOption {
              type = lib.types.nullOr (lib.types.either lib.types.ints.positive (lib.types.enum [ "auto" ]));
              default = null;
              description = ''
                Passage budget of the gap step's prompt, or "auto" for all the
                room the window leaves. Null keeps wosarcher's default, 4000.
              '';
            };
          };
        }
      );
      description = ''
        Models by id (an OmniRoute model or combo, or an agents
        <agent>/<model> id). Each lands in the `models` table of its
        endpoint's llm entry with its context window, output limit,
        reasoning, and gap budget. A run may pick any model of an entry; one
        not listed gets wosarcher's 32768/8192 fallback.
      '';
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf toml.type;
      default = { };
      description = ''
        Profiles passed to services.wosarcher.profiles, which copies them to
        /var/lib/wosarcher/config/wosarcher/profiles/<name>.toml. A profile
        is thin: `use` names one entry per block, and it sets only profile
        keys (llm.model, domain lists, select.*, run.*). The generated
        profiles are `default` (embeddings and the shared reranker, or bm25
        without it, with OmniRoute) and, with jev.enable, `jev` (the same
        with the jev-strict scorer); each of their keys can be overridden.
        Provider entries (searxng, firecrawl, embeddings, rerank, jev,
        jev-strict, and one llm entry per endpoint) and the `wide` depth
        preset are set in services.wosarcher.providers and
        services.wosarcher.depths, where a host can override them too.
      '';
    };

    jev.enable = lib.mkEnableOption ''
      the TypeSafe Jev scorer: adds the jev and jev-strict score entries and
      the jev profile, which read personal-typesafe-api-key from
      secrets-sops/personal.yaml through api_key_file
    '';

    passwordHashSecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          SOPS file with the admin password's scrypt hash (from
          `wosarcherd auth set-password --print`), passed to the daemon as
          auth.password_hash_file. Null keeps the hash the daemon stores
          itself with `sudo -u wosarcher wosarcherd auth set-password`.
        '';
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "local-wosarcher-password-hash";
        description = "Key containing the admin password hash in the SOPS file.";
      };
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Extra WOSARCHER_* variables for the service, for example
        WOSARCHER_SERVER__LOG_LEVEL or WOSARCHER_USE__SCORE. systemd reads it
        as root; nothing else does. Provider keys and secrets go in entries
        instead (see passwordHashSecret for the admin password).
      '';
    };
  };

  config = lib.mkIf (cfg.enable && wcfg.enable) {
    _custom.services.ai.wosarcher.models = {
      # OmniRoute's research-smart combo: DeepSeek V4 Flash, 1M context.
      research-smart = {
        preset = lib.mkDefault "deepseek-v4-flash";
        # The gap step reads the best passages so far; "auto" gives it all the
        # room the 1M window leaves instead of wosarcher's 4000-token default.
        gapContextTokens = lib.mkDefault "auto";
        # Measured on one run: low thinking at write time lifted citation
        # faithfulness from 0.52 to 0.64 with the same passages.
        reasoning.write = lib.mkDefault "low";
      };
      # OmniRoute's desktop-free combo (free Gemma 4 31B, then Ollama Cloud,
      # then the local gdesktop-qwen3.5:9b). The combo can fall back to the
      # local 32k model, so size for the smallest member. Prompt processing
      # of a large context on the local GPU is slow, hence omniroute's 600 s
      # timeout.
      desktop-free.preset = lib.mkDefault "qwen3-5-9b-local";
      # Claude through agents serve. Effort "none" (the write default) keeps
      # Claude Code's own effort: high for Sonnet, medium for Haiku.
      "claude/claude-sonnet-5-5" = lib.mkIf cfg.agentsServer.enable {
        endpoint = lib.mkDefault "agents";
        preset = lib.mkDefault "claude-sonnet-5-5";
        reasoning.plan = lib.mkDefault "low";
        reasoning.gap = lib.mkDefault "low";
      };
      "claude/claude-haiku-5-5" = lib.mkIf cfg.agentsServer.enable {
        endpoint = lib.mkDefault "agents";
        preset = lib.mkDefault "claude-haiku-5-5";
        reasoning.plan = lib.mkDefault "low";
        reasoning.gap = lib.mkDefault "low";
      };
    };

    assertions = [
      # The llm prompts carry scraped web text; with tools an agent could act
      # on instructions planted in it.
      {
        assertion = !usesAgents || (cfg.agentsServer.enable && !cfg.agentsServer.tools);
        message = "wosarcher: a model with endpoint = \"agents\" needs agentsServer enabled with tools = false";
      }
      {
        assertion = wcfg.profiles ? ${wcfg.profile};
        message = "wosarcher: profile \"${wcfg.profile}\" is not one of: ${lib.concatStringsSep ", " (lib.attrNames wcfg.profiles)}";
      }
    ]
    ++ lib.mapAttrsToList (name: _: {
      assertion = modelsOf name ? ${wcfg.endpoints.${name}.model};
      message = "wosarcher: endpoints.${name}.model \"${wcfg.endpoints.${name}.model}\" is not a model of ${name}; add it to models";
    }) usedEndpoints;

    _custom.services.ai.wosarcher.profiles = lib.mapAttrs (_: defaults) generatedProfiles;

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
      // lib.optionalAttrs (hashSecret.sopsFile != null) {
        WOSARCHER_AUTH__PASSWORD_HASH_FILE = config.sops.secrets.${hashSecret.sopsKey}.path;
      };
      environmentFile = wcfg.environmentFile;
      inherit (wcfg) profiles;
      providers = lib.mapAttrs (_: lib.mapAttrs (_: defaults)) generatedProviders;
      depths = lib.mapAttrs (_: defaults) generatedDepths;
    };

    users.users.wosarcher.uid = uid;
    users.groups.wosarcher.gid = gid;

    # Copies of the keys owned by the service user: the daemon reads them
    # itself when a run resolves its entries, so a rotated key reaches the
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
    sops.secrets.${hashSecret.sopsKey} = lib.mkIf (hashSecret.sopsFile != null) {
      inherit (hashSecret) sopsFile;
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
