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
    ./qwen3-asr
    ./article-page
    ./article-summary
    ./supertonic
  ];

  options._custom.services.ai = {
    enable = lib.mkEnableOption { };
    enablePix2tex = lib.mkEnableOption { };
    enableWhisper = lib.mkEnableOption { };
    enableOllama = lib.mkEnableOption { };
    enableOllamaFlashAttention = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
    enableOpenWebui = lib.mkEnableOption { };
    enableNextjsOllamaLlmUi = lib.mkEnableOption { };
    enableOmniRoute = lib.mkEnableOption "the local OmniRoute AI gateway";
    enableArticlePage = lib.mkEnableOption "the system-wide Markdown-to-HTML article-page renderer";
    enableArticleSummary = lib.mkEnableOption "system-wide article summarization and HTML rendering";
    enableSupertonic = lib.mkEnableOption "the local Supertonic text-to-speech service";
    enableQwen3Asr = lib.mkEnableOption "on-demand Qwen3-ASR-1.7B transcription with Transformers";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        python314Packages.huggingface-hub
        asr-videos
        oterm
        summary
      ]
      ++ lib.optionals cfg.enableWhisper [ (whisper-cpp.override { cudaSupport = cfg.enableNvidia; }) ]
      ++ lib.optionals cfg.enablePix2tex [ _custom.pythonPackages.pix2tex ];

    services.ollama = lib.mkIf cfg.enableOllama {
      enable = true;
      package = if cfg.enableNvidia then pkgs.ollama-cuda else pkgs.ollama;
      environmentVariables = {
        OLLAMA_ORIGINS = "*";
      }
      // lib.optionalAttrs cfg.enableOllamaFlashAttention {
        OLLAMA_FLASH_ATTENTION = "1";
      };
    };
    systemd.services.ollama = {
      wantedBy = lib.mkForce [ ];
      # unitConfig.stopWhenUnneeded = true;
    };

    systemd.services.open-webui.serviceConfig = lib.mkIf cfg.enableOpenWebui {
      # Preserve the upstream GPU device allow-list; PrivateDevices breaks acceleration.
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictSUIDSGID = true;
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
    };

    # TODO: enable socket activation
    # source: https://github.com/ollama/ollama/pull/8072
    # systemd.sockets.ollama = {
    #   description = "Ollama server socket";
    #   wantedBy = [ "sockets.target" ];
    #   listenStreams =
    #     [ "${config.services.ollama.host}:${toString config.services.ollama.port}" ];
    # };

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

    _custom.hm = {
      home = {
        packages = [ clean-voice ];

        shellAliases = {
          # transform wav 16kHz to vtt
          wis = "whisper-cli --model ~/Projects/wochap/whisper.cpp/models/ggml-large-v3.bin --output-vtt --file";
          # downloads youtube video and also generates a wav 16kHz format
          ytaw = "yt-dlp -f bestvideo+bestaudio --keep-video --add-metadata --xattrs --merge-output-format mp4 --extract-audio --audio-format wav --postprocessor-args 'ffmpeg:-ar 16000'";
        };

        file = {
          "Models/.keep".text = "";
        };
      };

      programs.zsh.initContent = lib.mkOrder 1000 (builtins.readFile ./dotfiles/whisper.zsh);
    };
  };
}
