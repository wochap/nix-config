{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  source = inputs."gpt-researcher";
  revision = source.rev or (throw "The gpt-researcher flake input must be locked to a Git revision");
  ociBackend = config.virtualisation.oci-containers.backend;

  apiServiceName = "${ociBackend}-gpt-researcher-api";
  apiUid = 1000;
  apiGid = 1000;
  webServiceName = "${ociBackend}-gpt-researcher-web";
  apiProxy = config._custom.services.web-proxies.gpt-researcher-api;
  firecrawlPublicPort = lib.attrByPath [
    "firecrawl"
    "publicPort"
  ] 20900 config._custom.services.web-proxies;
  omniRouteProxy = config._custom.services.web-proxies.omniroute;
  ollamaEmbeddingCompat = pkgs.writeText "langchain_ollama.py" ''
    from langchain_community.embeddings import OllamaEmbeddings

    __all__ = ["OllamaEmbeddings"]
  '';
  searxProxy = config._custom.services.web-proxies.searxng;
  webProxy = config._custom.services.web-proxies.gpt-researcher;

  # Named model presets: total context window and the largest completion the
  # provider accepts. Token limits below derive from these; VRAM is never an
  # input because it says nothing about how much context a model gets.
  modelPresets = {
    # https://api-docs.deepseek.com/quick_start/pricing (1M context, 384K max output)
    deepseek-v4-flash = {
      contextTokens = 1048576;
      maxOutputTokens = 384000;
    };
    # https://ai.google.dev/gemma/docs/core (256K context);
    # https://openrouter.ai/google/gemma-4-31b-it (32768 max completion)
    gemma4-31b = {
      contextTokens = 262144;
      maxOutputTokens = 32768;
    };
    # https://openrouter.ai/qwen/qwen3.8-max-0902 (1M context, 131072 max output)
    qwen3-8-max = {
      contextTokens = 1000000;
      maxOutputTokens = 131072;
    };
    # ../ollama/models/gdesktop-qwen3.5:9b (num_ctx 32768); output capped at
    # a quarter of the window so prompts keep room for scraped context.
    qwen3-5-9b-local = {
      contextTokens = 32768;
      maxOutputTokens = 8192;
    };
    # Reproduce the limits hand-tuned on glegion before presets existed:
    # 131072 smart / 12000 fast / 16000 strategic with a 256K window.
    glegion-cloud-smart = {
      contextTokens = 262144;
      maxOutputTokens = 131072;
    };
    glegion-cloud-fast = {
      contextTokens = 262144;
      maxOutputTokens = 12000;
    };
    glegion-cloud-strategic = {
      contextTokens = 262144;
      maxOutputTokens = 16000;
    };
  };

  modelType = lib.types.either lib.types.str (
    lib.types.submodule {
      options = {
        contextTokens = lib.mkOption {
          type = lib.types.ints.positive;
          description = "Total context window (prompt plus completion) in tokens.";
        };
        maxOutputTokens = lib.mkOption {
          type = lib.types.ints.positive;
          description = "Largest completion the provider accepts, in tokens.";
        };
      };
    }
  );

  presetNames = lib.concatStringsSep ", " (builtins.attrNames modelPresets);
  resolveModel =
    m:
    if builtins.isString m then
      modelPresets.${m}
        or (throw "gpt-researcher: unknown model preset \"${m}\"; known presets: ${presetNames}")
    else
      m;
  smartModel = resolveModel cfg.gptResearcherSmartModel;
  fastModel = resolveModel cfg.gptResearcherFastModel;
  strategicModel = resolveModel cfg.gptResearcherStrategicModel;
  embeddingCtx = cfg.ollamaEmbeddingContextTokens;

  # gpt_researcher/utils/llm.py rejects max_tokens above 200000 as a typo
  # guard, and 131072 is the largest limit proven to work through OmniRoute.
  maxOutputCap = 131072;

  # Never let a completion claim more than half the window; the prompt needs
  # the rest.
  outLimit = m: lib.min maxOutputCap (lib.min m.maxOutputTokens (m.contextTokens / 2));
  fastTokenLimit = outLimit fastModel;
  smartTokenLimit = outLimit smartModel;
  strategicTokenLimit = outLimit strategicModel;

  # Scale the research shape with the smart model's window.
  researchBreadth =
    if smartModel.contextTokens >= 100000 then
      4
    else if smartModel.contextTokens >= 32768 then
      3
    else
      2;

  derivedSettings = {
    # Local Ollama model used to embed and rank retrieved content.
    EMBEDDING = "ollama:${cfg.ollamaEmbeddingModel}";
    # FAST_TOKEN_LIMIT: leaves reasoning and response headroom for fast-model calls.
    FAST_TOKEN_LIMIT = toString fastTokenLimit;
    # SMART_TOKEN_LIMIT: prevents large structured reports from ending mid-response.
    SMART_TOKEN_LIMIT = toString smartTokenLimit;
    # STRATEGIC_TOKEN_LIMIT: provides room for reasoning during research planning.
    STRATEGIC_TOKEN_LIMIT = toString strategicTokenLimit;
    # TOTAL_WORDS: requests comprehensive output without forcing the full
    # token limit (about 1.4 tokens per word, plus headroom).
    TOTAL_WORDS = toString (lib.min 20000 (smartTokenLimit / 6));
    # MAX_ITERATIONS: generates more focused queries for broad research topics.
    MAX_ITERATIONS = toString researchBreadth;
    # MAX_SUBTOPICS: allows detailed reports to cover more independent sections.
    MAX_SUBTOPICS = toString researchBreadth;
    # BROWSE_CHUNK_MAX_LENGTH (chars): retains more useful text from long pages
    # while fitting both the fast model's prompt budget and the embedding window.
    BROWSE_CHUNK_MAX_LENGTH = toString (
      lib.min 24000 (lib.min ((fastModel.contextTokens - fastTokenLimit) * 2) (embeddingCtx * 3))
    );
    # SUMMARY_TOKEN_LIMIT: preserves more facts and citations in per-source summaries.
    SUMMARY_TOKEN_LIMIT = toString (lib.max 500 (fastTokenLimit / 6));
  };

  constantSettings = {
    # OmniRoute alias for summaries and other lightweight tasks.
    FAST_LLM = "openai:research-fast";
    # OmniRoute alias used to write the final research report.
    SMART_LLM = "openai:research-smart";
    # OmniRoute alias used for research planning and search queries.
    STRATEGIC_LLM = "openai:research-smart";
    # Keeps model reasoning enabled while limiting excessive deliberation.
    LLM_KWARGS = ''{"extra_body":{"enable_thinking":true,"reasoning_effort":"low"}}'';
    # Broadens coverage for every generated search query.
    MAX_SEARCH_RESULTS_PER_QUERY = "15";
    # Limits concurrent fetches to avoid overwhelming fragile sites.
    MAX_SCRAPER_WORKERS = "8";
    # Improves determinism and structured-output consistency.
    TEMPERATURE = "0.1";
    # Keeps generated reports consistently in English.
    LANGUAGE = "english";
    # Retains all gathered sources instead of selecting only the top ten.
    CURATE_SOURCES = "false";
    # Emits detailed pipeline events for future troubleshooting.
    VERBOSE = "true";
    # Connects the container to the host Ollama service.
    OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    # Authenticates GPT Researcher to the local OmniRoute API.
    OPENAI_API_KEY = config.sops.placeholder.local-omniroute-secret-key;
    # Routes OpenAI-compatible LLM calls through local OmniRoute.
    OPENAI_BASE_URL = "http://${wochap-ssc.meta.address}:${toString omniRouteProxy.publicPort}/v1";
    # Uses the self-hosted SearxNG metasearch retriever.
    RETRIEVER = "searx";
    # Scrapes retrieved pages through the local, lazily started Firecrawl API.
    SCRAPER = "firecrawl";
    FIRECRAWL_SERVER_URL = "http://${wochap-ssc.meta.address}:${toString firecrawlPublicPort}";
    FIRECRAWL_API_KEY = "";
    # Points the retriever at the local SearxNG proxy.
    SEARX_URL = "http://${wochap-ssc.meta.address}:${toString searxProxy.publicPort}";
  };

  researcherSettings = constantSettings // derivedSettings // cfg.gptResearcherSettings;
in
{
  options._custom.services.ai = {
    enableGptResearcher = lib.mkEnableOption { };

    gptResearcherEnvironmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Environment file containing GPT Researcher provider configuration and
        secrets, such as OPENAI_API_KEY and TAVILY_API_KEY.
      '';
    };

    gptResearcherSmartModel = lib.mkOption {
      type = modelType;
      default = "glegion-cloud-smart";
      description = ''
        Model behind the OmniRoute research-smart combo: a preset name
        (${presetNames}) or { contextTokens; maxOutputTokens; }.
      '';
    };

    gptResearcherFastModel = lib.mkOption {
      type = modelType;
      default = "glegion-cloud-fast";
      description = "Model behind the OmniRoute research-fast combo; same form as gptResearcherSmartModel.";
    };

    gptResearcherStrategicModel = lib.mkOption {
      type = modelType;
      default = cfg.gptResearcherSmartModel;
      defaultText = lib.literalExpression "config._custom.services.ai.gptResearcherSmartModel";
      description = "Model used for research planning; defaults to the smart model.";
    };

    gptResearcherSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        MAX_SUBTOPICS = "6";
      };
      description = "Raw GPT Researcher environment overrides, merged after the derived values.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.enableGptResearcher) {
    assertions =
      map
        (
          name:
          let
            value = cfg.${name};
          in
          {
            assertion = !(builtins.isString value) || modelPresets ? ${value};
            message = "_custom.services.ai.${name}: unknown preset \"${toString value}\"; known presets: ${presetNames}";
          }
        )
        [
          "gptResearcherSmartModel"
          "gptResearcherFastModel"
          "gptResearcherStrategicModel"
        ];

    _custom.services.web-proxies = {
      gpt-researcher = {
        enable = true;
        subdomain = "gpt-researcher";
        serviceName = webServiceName;
        publicPort = 20300;
        backendPort = 20301;
        lazy = true;
      };

      gpt-researcher-api = {
        enable = true;
        subdomain = "gpt-researcher-api";
        serviceName = apiServiceName;
        publicPort = 20800;
        backendPort = 20801;
        lazy = true;
      };
    };

    _custom.services.local-oci-images = {
      gpt-researcher-api = {
        inherit source;
        tag = revision;
        imageName = "gpt-researcher";
      };

      gpt-researcher-web = {
        inherit source;
        tag = revision;
        imageName = "gptr-nextjs";
        context = "frontend/nextjs";
        dockerfile = "Dockerfile.dev";
      };
    };

    virtualisation.oci-containers.containers = {
      gpt-researcher-api = {
        serviceName = apiServiceName;
        cmd = [
          "uvicorn"
          "main:app"
          "--host"
          wochap-ssc.meta.address
          "--port"
          (toString apiProxy.backendPort)
        ];
        volumes = [
          "${ollamaEmbeddingCompat}:/usr/src/app/langchain_ollama.py:ro"
          "/var/lib/gpt-researcher/data:/usr/src/app/data:rw"
          "/var/lib/gpt-researcher/my-docs:/usr/src/app/my-docs:rw"
          "/var/lib/gpt-researcher/outputs:/usr/src/app/outputs:rw"
          "/var/lib/gpt-researcher/logs:/usr/src/app/logs:rw"
        ];
        environment = {
          DOC_PATH = "/usr/src/app/my-docs";
          HOST = wochap-ssc.meta.address;
          IMAGE_GENERATION_ENABLED = "false";
          IMAGE_GENERATION_MAX_IMAGES = "3";
          IMAGE_GENERATION_MODEL = "gemini-2.0-flash-preview-image-generation";
          LOGGING_LEVEL = "INFO";
          OUTPUT_PATH = "/usr/src/app/outputs";
          PORT = toString apiProxy.backendPort;
          REPORT_STORE_PATH = "/usr/src/app/data/reports.json";
          REPORT_MAX_CONTINUATIONS = "3";
          REPORT_CONTINUATION_TAIL_CHARS = "65536";
        };
        environmentFiles = [
          config.sops.templates."gpt-researcher-omniroute.env".path
        ]
        ++ lib.optional (cfg.gptResearcherEnvironmentFile != null) cfg.gptResearcherEnvironmentFile;
        extraOptions = [
          "--network=host"
          "--cap-drop=all"
          "--security-opt=no-new-privileges"
          "--pids-limit=1024"
        ];
      };

      gpt-researcher-web = {
        serviceName = webServiceName;
        cmd = [
          "npm"
          "run"
          "dev"
          "--"
          "--hostname"
          wochap-ssc.meta.address
          "--port"
          (toString webProxy.backendPort)
        ];
        volumes = [ "/var/lib/gpt-researcher/outputs:/app/outputs:rw" ];
        environment = {
          HOSTNAME = wochap-ssc.meta.address;
          LOGGING_LEVEL = "INFO";
          NEXT_PUBLIC_BACKEND_URL = "http://${wochap-ssc.meta.address}:${toString apiProxy.publicPort}";
          NEXT_PUBLIC_GPTR_API_URL = "http://${wochap-ssc.meta.address}:${toString apiProxy.publicPort}";
          PORT = toString webProxy.backendPort;
        };
        extraOptions = [
          "--network=host"
          "--cap-drop=all"
          "--security-opt=no-new-privileges"
          "--pids-limit=512"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/gpt-researcher 0750 root root -"
      "d /var/lib/gpt-researcher/data 0750 ${toString apiUid} ${toString apiGid} -"
      "d /var/lib/gpt-researcher/logs 0750 ${toString apiUid} ${toString apiGid} -"
      "d /var/lib/gpt-researcher/my-docs 0750 ${toString apiUid} ${toString apiGid} -"
      "d /var/lib/gpt-researcher/outputs 0750 ${toString apiUid} ${toString apiGid} -"
      "Z /var/lib/gpt-researcher/* - ${toString apiUid} ${toString apiGid} -"
    ];

    sops.templates."gpt-researcher-omniroute.env" = {
      mode = "0400";
      restartUnits = [ "${apiServiceName}.service" ];
      content = lib.generators.toKeyValue { } researcherSettings;
    };

    systemd.services = {
      ${apiServiceName} = {
        requires = [ "ollama.service" ];
        after = [ "ollama.service" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStopSec = lib.mkForce 45;
          UMask = "0027";
          ProtectHome = true;
        };
      };

      ${webServiceName} = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStopSec = lib.mkForce 30;
          UMask = "0027";
          ProtectHome = true;
        };
      };
    };
  };
}
