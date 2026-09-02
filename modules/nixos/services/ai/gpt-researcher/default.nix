{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  apiProxy = config._custom.services.web-proxies.gpt-researcher-api;
  omniRouteProxy = config._custom.services.web-proxies.omniroute;
  ollamaEmbeddingCompat = pkgs.writeText "langchain_ollama.py" ''
    from langchain_community.embeddings import OllamaEmbeddings

    __all__ = ["OllamaEmbeddings"]
  '';
  searxProxy = config._custom.services.web-proxies.searxng;
  webProxy = config._custom.services.web-proxies.gpt-researcher;
in
{
  config = lib.mkIf (cfg.enable && cfg.enableGptResearcher) {
    _custom.services.web-proxies = {
      gpt-researcher = {
        enable = true;
        subdomain = "gpt-researcher";
        serviceName = "podman-gpt-researcher-web";
        publicPort = 20300;
        backendPort = 20301;
        lazy = true;
      };

      gpt-researcher-api = {
        enable = true;
        subdomain = "gpt-researcher-api";
        serviceName = "podman-gpt-researcher-api";
        publicPort = 20800;
        backendPort = 20801;
        lazy = true;
      };
    };

    virtualisation.oci-containers.containers = {
      gpt-researcher-api = {
        image = cfg.gptResearcherImage;
        user = "0:0";
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
          "/var/lib/gpt-researcher/my-docs:/usr/src/app/my-docs:rw"
          "/var/lib/gpt-researcher/outputs:/usr/src/app/outputs:rw"
          "/var/lib/gpt-researcher/logs:/usr/src/app/logs:rw"
        ];
        environment = {
          DOC_PATH = "/usr/src/app/my-docs";
          HOST = wochap-ssc.meta.address;
          LOGGING_LEVEL = "INFO";
          OUTPUT_PATH = "/usr/src/app/outputs";
          PORT = toString apiProxy.backendPort;
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
        image = cfg.gptResearcherWebImage;
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
          NEXT_PUBLIC_BACKEND_URL = "http://${wochap-ssc.meta.address}:${toString apiProxy.publicPort}";
          NEXT_PUBLIC_GPTR_API_URL = "https://${apiProxy.subdomain}.${wochap-ssc.meta.domain}";
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
      "d /var/lib/gpt-researcher/logs 0750 root root -"
      "d /var/lib/gpt-researcher/my-docs 0750 root root -"
      "d /var/lib/gpt-researcher/outputs 0750 root root -"
    ];

    sops.templates."gpt-researcher-omniroute.env" = {
      mode = "0400";
      restartUnits = [ "podman-gpt-researcher-api.service" ];
      content = ''
        # Local Ollama model used to embed and rank retrieved content.
        EMBEDDING=ollama:glegion-qwen3-embedding:4b
        # OmniRoute alias for summaries and other lightweight tasks.
        FAST_LLM=openai:research-fast
        # Leaves reasoning and response headroom for fast-model calls.
        FAST_TOKEN_LIMIT=12000
        # OmniRoute alias used to write the final research report.
        SMART_LLM=openai:research-smart
        # Prevents large structured reports from ending mid-response.
        SMART_TOKEN_LIMIT=131072
        # OmniRoute alias used for research planning and search queries.
        STRATEGIC_LLM=openai:research-smart
        # Provides ample room for reasoning during research planning.
        STRATEGIC_TOKEN_LIMIT=16000
        # Keeps model reasoning enabled while limiting excessive deliberation.
        LLM_KWARGS={"extra_body":{"enable_thinking":true,"reasoning_effort":"low"}}
        # Requests comprehensive output without forcing the full token limit.
        TOTAL_WORDS=20000
        # Broadens coverage for every generated search query.
        MAX_SEARCH_RESULTS_PER_QUERY=15
        # Generates more focused queries for broad research topics.
        MAX_ITERATIONS=8
        # Allows detailed reports to cover more independent sections.
        MAX_SUBTOPICS=8
        # Limits concurrent fetches to avoid overwhelming fragile sites.
        MAX_SCRAPER_WORKERS=8
        # Retains more useful text from long official pages and documents.
        BROWSE_CHUNK_MAX_LENGTH=24000
        # Preserves more facts and citations in per-source summaries.
        SUMMARY_TOKEN_LIMIT=2000
        # Improves determinism and structured-output consistency.
        TEMPERATURE=0.1
        # Keeps generated reports consistently in English.
        LANGUAGE=english
        # Retains all gathered sources instead of selecting only the top ten.
        CURATE_SOURCES=false
        # Emits detailed pipeline events for future troubleshooting.
        VERBOSE=true
        # Connects the container to the host Ollama service.
        OLLAMA_BASE_URL=http://127.0.0.1:11434
        # Authenticates GPT Researcher to the local OmniRoute API.
        OPENAI_API_KEY=${config.sops.placeholder.local-omniroute-secret-key}
        # Routes OpenAI-compatible LLM calls through local OmniRoute.
        OPENAI_BASE_URL=http://${wochap-ssc.meta.address}:${toString omniRouteProxy.publicPort}/v1
        # Uses the self-hosted SearxNG metasearch retriever.
        RETRIEVER=searx
        # Extracts page text with lightweight Beautiful Soup scraping.
        SCRAPER=bs
        # Points the retriever at the local SearxNG proxy.
        SEARX_URL=http://${wochap-ssc.meta.address}:${toString searxProxy.publicPort}
      '';
    };

    systemd.services = {
      podman-gpt-researcher-api = {
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

      podman-gpt-researcher-web.serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = lib.mkForce 30;
        UMask = "0027";
        ProtectHome = true;
      };
    };
  };
}
