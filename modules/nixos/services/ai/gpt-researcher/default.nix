{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  gcfg = cfg.gptResearcher;
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

  # Retrieval reranking through the shared llama-server reranker
  # (../reranker), reached via its lazy socket proxy.
  rcfg = gcfg.reranker;
  reranker = cfg.reranker;
  rerankerProxy = config._custom.services.web-proxies.reranker;

  rerankerSettings = lib.optionalAttrs rcfg.enable {
    # Replaces the stock embedding filter with chunking -> cosine top-K ->
    # rerank (gpt_researcher/context/rerank_compression.py).
    RETRIEVAL_PIPELINE = "local_gpu";
    RERANKER_ENABLED = "true";
    RERANKER_PROVIDER = "llamacpp";
    # Goes through the lazy socket proxy so the first rerank starts llama-server.
    RERANKER_BASE_URL = "http://${wochap-ssc.meta.address}:${toString rerankerProxy.publicPort}";
    RERANKER_ENDPOINT = reranker.endpoint;
    RERANKER_MODEL = reranker.model;
    RERANKER_TOP_K = toString rcfg.rerankTopK;
    RERANKER_BATCH_SIZE = toString rcfg.rerankBatchSize;
    RERANKER_TIMEOUT = toString rcfg.timeoutSeconds;
    # llama-server applies the GGUF's own rerank template, so wrapping the
    # query and documents again would nest it twice.
    RERANKER_APPLY_QWEN3_TEMPLATE = lib.boolToString rcfg.applyQwen3Template;
    EMBEDDING_TOP_K = toString rcfg.embeddingTopK;
    EMBEDDING_BATCH_SIZE = toString rcfg.embeddingBatchSize;
    COMPRESSION_CHUNK_SIZE = toString rcfg.chunkSize;
    COMPRESSION_CHUNK_OVERLAP = toString rcfg.chunkOverlap;
  };

  # Total context window and largest completion per model (../model-presets.nix).
  models = import ../model-presets.nix { inherit lib; };
  modelType = models.type;
  presetNames = models.names;
  resolveModel = models.resolve "gpt-researcher";
  smartModel = resolveModel gcfg.smartModel;
  fastModel = resolveModel gcfg.fastModel;
  strategicModel = resolveModel gcfg.strategicModel;
  embeddingCtx = gcfg.embeddingContextTokens;

  # gpt_researcher/utils/llm.py rejects max_tokens above 200000 as a typo
  # guard, and 131072 is the largest limit proven to work through OmniRoute.
  inherit (models) maxOutputCap;

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

  researcherSettings = constantSettings // derivedSettings // rerankerSettings // gcfg.settings;
in
{
  options._custom.services.ai.gptResearcher = {
    enable = lib.mkEnableOption { };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Environment file containing GPT Researcher provider configuration and
        secrets, such as OPENAI_API_KEY and TAVILY_API_KEY.
      '';
    };

    smartModel = lib.mkOption {
      type = modelType;
      default = "glegion-cloud-smart";
      description = ''
        Model behind the OmniRoute research-smart combo: a preset name
        (${presetNames}) or { contextTokens; maxOutputTokens; }.
      '';
    };

    fastModel = lib.mkOption {
      type = modelType;
      default = "glegion-cloud-fast";
      description = "Model behind the OmniRoute research-fast combo; same form as smartModel.";
    };

    strategicModel = lib.mkOption {
      type = modelType;
      default = gcfg.smartModel;
      defaultText = lib.literalExpression "config._custom.services.ai.gptResearcher.smartModel";
      description = "Model used for research planning; defaults to the smart model.";
    };

    embeddingContextTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 24576;
      description = ''
        Context window of ollamaEmbeddingModel. Must match the num_ctx
        parameter in its Modelfile; it bounds how much scraped text is
        embedded per chunk.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        MAX_SUBTOPICS = "6";
      };
      description = "Raw GPT Researcher environment overrides, merged after the derived values.";
    };

    reranker = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.reranker.enable;
        defaultText = lib.literalExpression "config._custom.services.ai.reranker.enable";
        description = ''
          Use the shared reranker (_custom.services.ai.reranker) in the
          retrieval stage (RETRIEVAL_PIPELINE=local_gpu).
        '';
      };

      applyQwen3Template = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Wrap the query and documents in the Qwen3-Reranker chat template
          client-side. Leave off for GGUFs carrying
          tokenizer.chat_template.rerank: llama-server applies that itself and
          templating twice flattens the score spread.
        '';
      };

      timeoutSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 60;
        description = ''
          Timeout for each rerank request. llama-server loads a GGUF in
          seconds, so this only has to cover the request itself plus the lazy
          proxy's first start.
        '';
      };

      embeddingTopK = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Chunks kept by cosine similarity and handed to the reranker.";
      };

      embeddingBatchSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 16;
        description = "Chunks per Ollama embedding request.";
      };

      rerankTopK = lib.mkOption {
        type = lib.types.ints.positive;
        default = 8;
        description = "Reranked chunks handed to the LLM per sub-query.";
      };

      rerankBatchSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 8;
        description = "Documents per rerank request.";
      };

      chunkSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 2000;
        description = ''
          Characters per chunk. Must fit reranker.contextSize together with the rerank
          template and the query (about 4 characters per token).
        '';
      };

      chunkOverlap = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 200;
        description = "Characters shared by neighbouring chunks.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && gcfg.enable) {
    assertions =
      map
        (
          name:
          let
            value = gcfg.${name};
          in
          {
            assertion = !(builtins.isString value) || models.presets ? ${value};
            message = "_custom.services.ai.gptResearcher.${name}: unknown preset \"${toString value}\"; known presets: ${presetNames}";
          }
        )
        [
          "smartModel"
          "fastModel"
          "strategicModel"
        ]
      ++ [
        {
          assertion = !rcfg.enable || reranker.enable;
          message = "_custom.services.ai.gptResearcher.reranker.enable needs _custom.services.ai.reranker.enable";
        }
        {
          assertion = !rcfg.enable || (rcfg.chunkSize / 4 + 512 <= reranker.contextSize);
          message = "_custom.services.ai.gptResearcher.reranker: chunkSize ${toString rcfg.chunkSize} does not fit reranker.contextSize ${toString reranker.contextSize} with the rerank template and query";
        }
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
        ++ lib.optional (gcfg.environmentFile != null) gcfg.environmentFile;
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
