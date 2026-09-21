{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  clean-voice = pkgs.writeScriptBin "clean-voice" (builtins.readFile ./scripts/clean-voice.sh);
  summary = pkgs.writeScriptBin "summary" (builtins.readFile ./scripts/summary.sh);
  asr-videos = pkgs.writeScriptBin "asr-videos" (builtins.readFile ./scripts/asr-videos.sh);
in
{
  imports = [
    ./omniroute
    ./firecrawl
    ./gpt-researcher
    ./qwen3-asr
    ./article-page
    ./article-scrape
    ./article-summary
    ./course-notes
    ./supertonic
    ./ocr
    ./ollama
  ];

  options._custom.services.ai = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
    enableRocm = lib.mkEnableOption { };
    enableOpenWebui = lib.mkEnableOption { };
    enableNextjsOllamaLlmUi = lib.mkEnableOption { };
    enableHandy = lib.mkEnableOption { };

    ollamaEmbeddingModel = lib.mkOption {
      type = lib.types.str;
      default = "glegion-qwen3-embedding:4b";
      description = ''
        Local Ollama model shared by Firecrawl and GPT Researcher for
        embeddings. Its Modelfile lives in ./ollama/models.
      '';
    };

    ollamaEmbeddingContextTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 24576;
      description = ''
        Context window of ollamaEmbeddingModel. Must match the num_ctx
        parameter in its Modelfile; it bounds how much scraped text is
        embedded per chunk.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        python314Packages.huggingface-hub
      ]
      ++ lib.optionals cfg.enableHandy [ inputs.handy.packages.${stdenv.hostPlatform.system}.handy ];

    systemd.services.open-webui.serviceConfig = lib.mkIf cfg.enableOpenWebui {
      # Preserve the upstream GPU device allow-list; PrivateDevices breaks acceleration.
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictSUIDSGID = true;
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
    };

    # Register Web Proxies mapping configuration
    _custom.services.web-proxies = {
      # Make nextjs-ollama-llm-ui accessible at https://nolui.wochap.local
      nextjs-ollama-llm-ui = {
        enable = cfg.enableNextjsOllamaLlmUi;
        subdomain = "nolui";
        publicPort = 11464;
        lazy = true;
      };
      # Make openwebui accessible at https://openwebui.wochap.local
      open-webui = {
        enable = cfg.enableOpenWebui;
        subdomain = "openwebui";
        publicPort = 11454;
        lazy = true;
      };
    };

    services.nextjs-ollama-llm-ui = lib.mkIf cfg.enableNextjsOllamaLlmUi {
      enable = true;
      package = pkgs.nextjs-ollama-llm-ui;
      hostname = wochap-ssc.meta.address;
      port = config._custom.services.web-proxies.nextjs-ollama-llm-ui.backendPort;
    };

    services.open-webui = lib.mkIf cfg.enableOpenWebui {
      enable = true;
      package = pkgs.open-webui;
      openFirewall = false;
      host = wochap-ssc.meta.address;
      port = config._custom.services.web-proxies.open-webui.backendPort;
      environment = {
        WEBUI_AUTH = "False";
      };
    };

    _custom.hm.home.packages = [
      clean-voice
      asr-videos
      summary
    ];
  };
}
