{
  config,
  pkgs,
  lib,
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
    ./supertonic
    ./ocr
    ./ollama
  ];

  options._custom.services.ai = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
    enableOpenWebui = lib.mkEnableOption { };
    enableNextjsOllamaLlmUi = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      python314Packages.huggingface-hub
    ];

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
