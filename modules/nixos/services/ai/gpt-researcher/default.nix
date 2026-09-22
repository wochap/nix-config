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

  # llama.cpp reranker (gpt_researcher/context/reranker.py): a Qwen3-Reranker
  # GGUF served by llama-server behind /v1/rerank. llama.cpp allocates only
  # weights plus KV cache, so the reranker and the Ollama embedding model stay
  # resident on the same GPU and need no phase scheduling.
  rcfg = gcfg.reranker;
  rerankerServiceName = "gpt-researcher-reranker";
  rerankerModelServiceName = "${rerankerServiceName}-model";
  rerankerProxy = config._custom.services.web-proxies.gpt-researcher-reranker;
  rerankerIsRocm = rcfg.accelerator == "rocm";
  rerankerModelDir = "/var/lib/gpt-researcher/reranker";
  rerankerModelPath = "${rerankerModelDir}/${rcfg.modelFile}";
  # --pooling rank selects the classifier head the reranker GGUF carries; the
  # server applies the model's own tokenizer.chat_template.rerank per pair.
  rerankerCmd = [
    (lib.getExe' rcfg.package "llama-server")
    "--model"
    rerankerModelPath
    "--rerank"
    "--pooling"
    "rank"
    "--ctx-size"
    (toString rcfg.contextSize)
    "--n-gpu-layers"
    (toString rcfg.gpuLayers)
    "--host"
    wochap-ssc.meta.address
    "--port"
    (toString rerankerProxy.backendPort)
  ]
  # /metrics carries the token counters the idle watchdog samples.
  ++ lib.optional (rcfg.idleTimeout != null) "--metrics"
  ++ rcfg.extraArgs;

  # The GGUF lives outside the store: it is several GB, and pinning it there
  # would re-download it on every URL change. Verified against modelSha256
  # when one is set; the recorded hash doubles as the skip marker.
  fetchRerankerModel = pkgs.writeShellScript "fetch-gpt-researcher-reranker-model" ''
    set -euo pipefail
    curl=${lib.getExe pkgs.curl}
    sha256sum=${lib.getExe' pkgs.coreutils "sha256sum"}
    model=${lib.escapeShellArg rerankerModelPath}
    url=${lib.escapeShellArg rcfg.modelUrl}
    want=${lib.escapeShellArg (if rcfg.modelSha256 == null then "" else rcfg.modelSha256)}
    stamp="$model.sha256"

    if [ -f "$model" ]; then
      if [ -z "$want" ] || [ "$(cat "$stamp" 2>/dev/null || true)" = "$want" ]; then
        exit 0
      fi
      echo "Reranker model present but does not match modelSha256; re-downloading" >&2
    fi

    "$curl" --location --fail --retry 5 --retry-delay 5 --continue-at - \
      --output "$model.part" "$url"

    got="$("$sha256sum" "$model.part" | cut -d' ' -f1)"
    if [ -n "$want" ] && [ "$got" != "$want" ]; then
      echo "Reranker model sha256 mismatch: expected $want, got $got" >&2
      rm -f "$model.part"
      exit 1
    fi

    mv "$model.part" "$model"
    printf '%s' "$got" > "$stamp"
    echo "Reranker model ready: $model (sha256 $got)"
  '';

  # llama.cpp never unloads on its own, so the server would hold its VRAM
  # until something stops it. Sample the served-token counter: while it stands
  # still no rerank has been served, and after idleTimeout the unit stops. The
  # lazy socket proxy starts it again on the next request, at a few seconds'
  # cost.
  rerankerIdleWatchdog = pkgs.writeShellScript "gpt-researcher-reranker-idle" ''
    set -euo pipefail
    curl=${lib.getExe pkgs.curl}
    jq=${lib.getExe pkgs.jq}
    systemctl=${lib.getExe' pkgs.systemd "systemctl"}
    unit=${lib.escapeShellArg "${rerankerServiceName}.service"}
    base=http://${wochap-ssc.meta.address}:${toString rerankerProxy.backendPort}
    idle=${toString (rcfg.idleTimeout * 60)}
    state=/run/gpt-researcher-reranker-idle

    "$systemctl" is-active --quiet "$unit" || exit 0

    # Rises once per decode batch. llamacpp:prompt_tokens_total stays at 0 for
    # pooling requests, so it cannot serve as the activity signal here.
    served="$("$curl" -sf --max-time 5 "$base/metrics" \
      | ${lib.getExe pkgs.gawk} '/^llamacpp:n_decode_total /{print $2}')" || exit 0
    [ -n "$served" ] || exit 0

    now="$(date +%s)"
    last_served=""
    last_change="$now"
    if [ -f "$state" ]; then
      read -r last_served last_change < "$state" || true
    fi

    if [ "$served" != "$last_served" ]; then
      echo "$served $now" > "$state"
      exit 0
    fi

    # Never stop mid-request: a batch in flight leaves a slot processing.
    if "$curl" -sf --max-time 5 "$base/slots" | "$jq" -e 'any(.[]; .is_processing)' > /dev/null; then
      echo "$served $now" > "$state"
      exit 0
    fi

    if [ "$((now - last_change))" -ge "$idle" ]; then
      echo "No rerank served in ${toString rcfg.idleTimeout} min; stopping $unit to release its VRAM"
      rm -f "$state"
      "$systemctl" stop "$unit"
    fi
  '';

  rerankerSettings = lib.optionalAttrs rcfg.enable {
    # Replaces the stock embedding filter with chunking -> cosine top-K ->
    # rerank (gpt_researcher/context/rerank_compression.py).
    RETRIEVAL_PIPELINE = "local_gpu";
    RERANKER_ENABLED = "true";
    RERANKER_PROVIDER = "llamacpp";
    # Goes through the lazy socket proxy so the first rerank starts llama-server.
    RERANKER_BASE_URL = "http://${wochap-ssc.meta.address}:${toString rerankerProxy.publicPort}";
    RERANKER_ENDPOINT = rcfg.endpoint;
    RERANKER_MODEL = rcfg.model;
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
  smartModel = resolveModel gcfg.smartModel;
  fastModel = resolveModel gcfg.fastModel;
  strategicModel = resolveModel gcfg.strategicModel;
  embeddingCtx = gcfg.embeddingContextTokens;

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
      enable = lib.mkEnableOption "the llama-server reranker stage (RETRIEVAL_PIPELINE=local_gpu)";

      accelerator = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "cuda"
            "rocm"
          ]
        );
        default =
          if cfg.enableCuda then
            "cuda"
          else if cfg.enableRocm then
            "rocm"
          else
            null;
        defaultText = lib.literalExpression ''"cuda" when enableCuda, "rocm" when enableRocm'';
        description = "GPU backend; selects the default llama.cpp package.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default =
          if rerankerIsRocm then pkgs.llama-cpp-rocm else pkgs.llama-cpp.override { cudaSupport = true; };
        defaultText = lib.literalExpression "pkgs.llama-cpp-rocm on ROCm, pkgs.llama-cpp.override { cudaSupport = true; } on CUDA";
        example = lib.literalExpression "pkgs.llama-cpp-vulkan";
        description = ''
          llama.cpp build serving the reranker. llama-cpp-rocm comes from
          cache.nixos.org and already covers every gfx target ROCm itself was
          built for, gfx1030 included. The CUDA build is not cached and
          compiles locally; pkgs.llama-cpp-vulkan is the cached alternative on
          NVIDIA, at some throughput cost.
        '';
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "Qwen/Qwen3-Reranker-4B";
        description = ''
          Model name sent in each rerank request. llama-server ignores it in
          single-model mode; the served weights come from modelUrl.
        '';
      };

      modelUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF/resolve/main/Qwen3-Reranker-4B.Q8_0.gguf";
        description = ''
          GGUF downloaded once into ${rerankerModelDir}. It must come from a
          conversion through llama.cpp's reranker path: such files carry the
          cls.output.weight tensor and a tokenizer.chat_template.rerank key.
          A plain causal-LM Qwen3-Reranker conversion has no classifier head
          and cannot rerank.
        '';
      };

      modelSha256 = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "0b1c…";
        description = ''
          Expected sha256 of the GGUF. null downloads without verification and
          logs the hash it got, which is what you pin here afterwards.
        '';
      };

      modelFile = lib.mkOption {
        type = lib.types.str;
        default = baseNameOf rcfg.modelUrl;
        defaultText = lib.literalExpression "baseNameOf modelUrl";
        description = "File name the GGUF is stored under inside ${rerankerModelDir}.";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "/v1/rerank";
        description = ''
          Rerank path on llama-server. Builds have exposed /rerank,
          /v1/rerank and /v1/reranking; all take the same request shape.
        '';
      };

      contextSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4096;
        description = ''
          llama-server --ctx-size. Must cover the rerank template plus the
          query plus one chunk of chunkSize characters.
        '';
      };

      idleTimeout = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = 15;
        example = lib.literalExpression "null";
        description = ''
          Minutes without a served rerank after which the server is stopped
          and its VRAM released; the lazy proxy restarts it on the next
          request. null keeps it resident once started.
        '';
      };

      gpuLayers = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 99;
        description = "llama-server --n-gpu-layers; 99 offloads the whole model.";
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
          Characters per chunk. Must fit contextSize together with the rerank
          template and the query (about 4 characters per token).
        '';
      };

      chunkOverlap = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 200;
        description = "Characters shared by neighbouring chunks.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "--parallel"
          "4"
        ];
        description = "Extra arguments appended to llama-server.";
      };

      rocm.gfxOverride = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "10.3.0";
        description = ''
          HSA_OVERRIDE_GFX_VERSION, for a card that needs to present itself as
          another architecture. Unnecessary for any target llama-cpp-rocm
          already covers.
        '';
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
            assertion = !(builtins.isString value) || modelPresets ? ${value};
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
          assertion = !rcfg.enable || rcfg.accelerator != null;
          message = ''
            _custom.services.ai.gptResearcher.reranker.enable needs a GPU backend: set
            enableCuda, enableRocm, or _custom.services.ai.gptResearcher.reranker.accelerator.
          '';
        }
        {
          assertion = !rcfg.enable || (rcfg.chunkSize / 4 + 512 <= rcfg.contextSize);
          message = "_custom.services.ai.gptResearcher.reranker: chunkSize ${toString rcfg.chunkSize} does not fit contextSize ${toString rcfg.contextSize} with the rerank template and query";
        }
        {
          assertion = !rcfg.enable || lib.hasSuffix ".gguf" rcfg.modelFile;
          message = "_custom.services.ai.gptResearcher.reranker.modelFile must name a .gguf; llama-server serves GGUF weights only";
        }
      ];

    _custom.services.web-proxies = {
      gpt-researcher-reranker = lib.mkIf rcfg.enable {
        enable = true;
        subdomain = "gpt-researcher-reranker";
        serviceName = rerankerServiceName;
        publicPort = 20820;
        backendPort = 20821;
        lazy = true;
      };

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
    ]
    # llama-server runs as root; keep the GGUF out of the recursive chown above.
    ++ lib.optionals rcfg.enable [
      "d ${rerankerModelDir} 0750 root root -"
      "Z ${rerankerModelDir} - root root -"
    ];

    systemd.timers."${rerankerServiceName}-idle" = lib.mkIf (rcfg.enable && rcfg.idleTimeout != null) {
      description = "Check whether the GPT Researcher reranker has gone idle";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1min";
        AccuracySec = "30s";
      };
    };

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

      # Downloading several GB cannot happen inside the lazy proxy's start
      # window, so the GGUF is fetched at boot, independently of the server.
      ${rerankerModelServiceName} = lib.mkIf rcfg.enable {
        description = "Download the GPT Researcher reranker GGUF";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "2h";
          ExecStart = fetchRerankerModel;
          UMask = "0027";
          ProtectHome = true;
        };
      };

      "${rerankerServiceName}-idle" = lib.mkIf (rcfg.enable && rcfg.idleTimeout != null) {
        description = "Stop the GPT Researcher reranker once it has gone idle";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = rerankerIdleWatchdog;
        };
      };

      ${rerankerServiceName} = lib.mkIf rcfg.enable {
        description = "Qwen3-Reranker served by llama-server for GPT Researcher";
        requires = [ "${rerankerModelServiceName}.service" ];
        after = [ "${rerankerModelServiceName}.service" ];
        # A server that cannot start must not be restarted forever: it would
        # hold VRAM in a loop while the embedding model needs it.
        startLimitIntervalSec = 300;
        startLimitBurst = 3;
        environment = lib.optionalAttrs (rerankerIsRocm && rcfg.rocm.gfxOverride != null) {
          HSA_OVERRIDE_GFX_VERSION = rcfg.rocm.gfxOverride;
        };
        serviceConfig = {
          ExecStart = lib.escapeShellArgs rerankerCmd;
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStopSec = 60;
          UMask = "0027";
          ProtectHome = true;
          # The GGUF is the only state it touches, and only for reading.
          ProtectSystem = "strict";
          ReadOnlyPaths = [ rerankerModelDir ];
          NoNewPrivileges = true;
          PrivateTmp = true;
        };
      };
    };
  };
}
