{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (config._custom.globals) userName;
  inherit (pkgs._custom) wochap-ssc;
  omniroute-chat = pkgs.writeScriptBin "omniroute-chat" (
    builtins.readFile ./scripts/omniroute-chat.sh
  );
  tts-clipboard = pkgs.writeScriptBin "tts-clipboard" (builtins.readFile ./scripts/tts-clipboard.sh);
  voice-clean = pkgs.writeScriptBin "voice-clean" (builtins.readFile ./scripts/voice-clean.sh);
  qwen3-asr-transformers = pkgs.writeText "qwen3-asr-transformers.py" (
    builtins.readFile ./scripts/qwen3-asr-transformers.py
  );
  qwen3-asr-transcribe = pkgs.writeShellApplication {
    name = "qwen3-asr-transcribe";
    runtimeEnv = {
      QWEN3_ASR_IMAGE = "docker.io/qwenllm/qwen3-asr@sha256:fb75b775f089e06e5a1aaebffd421e37505cc630d50c86d889d95ffa45a7e16a";
      QWEN3_ASR_SCRIPT = qwen3-asr-transformers;
    };
    text = builtins.readFile ./scripts/qwen3-asr-transcribe.sh;
  };
  qwen3-asr-video = pkgs.writeScriptBin "qwen3-asr-video" (
    builtins.readFile ./scripts/qwen3-asr-video.sh
  );
in
{
  imports = [ ./ollama-webui-lite.nix ];

  options._custom.services.ai = {
    enable = lib.mkEnableOption { };
    enablePix2tex = lib.mkEnableOption { };
    enableWhisper = lib.mkEnableOption { };
    enableOllama = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
    enableOpenWebui = lib.mkEnableOption { };
    enableOllamaWebuiLite = lib.mkEnableOption { };
    enableNextjsOllamaLlmUi = lib.mkEnableOption { };
    enableOmniRoute = lib.mkEnableOption "the local OmniRoute AI gateway";
    enableOllamaFlashAttention = lib.mkEnableOption { };
    enableSupertonic = lib.mkEnableOption "the local Supertonic text-to-speech service";
    enableQwen3Asr = lib.mkEnableOption "on-demand Qwen3-ASR-1.7B transcription with Transformers";
  };

  config = lib.mkIf cfg.enable {
    # NOTE: cudaSupport rebuild opencv everytime nixpkgs changes
    # maybe this is unnecessary for ollama but necessary for docker
    # nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;

    sops.secrets.local-omniroute-secret-key = lib.mkIf cfg.enableOmniRoute {
      sopsFile = ../../../../secrets-sops/local.yaml;
      owner = userName;
    };

    environment.systemPackages =
      with pkgs;
      [
        python314Packages.huggingface-hub
        oterm
      ]
      ++ lib.optionals cfg.enableWhisper [ (whisper-cpp.override { cudaSupport = cfg.enableNvidia; }) ]
      ++ lib.optionals cfg.enablePix2tex [ _custom.pythonPackages.pix2tex ]
      ++ lib.optionals cfg.enableOmniRoute [ omniroute-chat ]
      ++ lib.optionals cfg.enableQwen3Asr [
        qwen3-asr-transcribe
        qwen3-asr-video
      ];

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

    _custom.hm.systemd.user.services.supertonic = lib.mkIf cfg.enableSupertonic {
      Unit = {
        Description = "Supertonic text-to-speech service";
        Documentation = "https://supertone-inc.github.io/supertonic-py/quickstart/#local-server";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs._custom.supertonic} serve --host 127.0.0.1 --port 7788";
        Restart = "on-failure";
        RestartSec = 2;
        # PERF: test those env vars
        # "SUPERTONIC_INTRA_OP_THREADS=8"
        # "SUPERTONIC_INTER_OP_THREADS=8"
        Environment = [ "HF_HUB_DISABLE_TELEMETRY=1" ];
      }
      // lib._custom.userServiceHardening
      // {
        ProtectHome = "tmpfs";
        BindPaths = [
          "%h/.cache/supertonic3"
          "%h/.cache/huggingface"
        ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
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
      # Make ollama-webui-lite accessible at https://ollama.wochap.local
      ollama-webui-lite = {
        enable = cfg.enableOllamaWebuiLite;
        subdomain = "ollama";
        publicPort = 11444;
        lazy = true;
      };
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
      # Make OmniRoute accessible at https://omniroute.wochap.local
      omniroute = {
        enable = cfg.enableOmniRoute;
        subdomain = "omniroute";
        publicPort = 20128;
        backendPort = 20129;
        serviceName = "podman-omniroute";
        lazy = true;
      };
    };

    virtualisation.oci-containers.containers.omniroute = lib.mkIf cfg.enableOmniRoute {
      image = "ghcr.io/diegosouzapw/omniroute:3.8.49@sha256:92c768c56e2de32c51a0621ef182835018b00b288c9bb235c5c5e4514658c1a1";
      volumes = [ "/var/lib/omniroute:/app/data" ];
      environment = {
        DATA_DIR = "/app/data";
        HOSTNAME = wochap-ssc.meta.address;
        PORT = toString config._custom.services.web-proxies.omniroute.backendPort;
        NEXT_PUBLIC_BASE_URL = "https://omniroute.${wochap-ssc.meta.domain}";
        OMNIROUTE_ALLOW_LOCAL_PROVIDER_URLS = "true";
      };
      extraOptions = [
        "--network=host"
        "--user=1000:1000"
        "--cap-drop=all"
        "--security-opt=no-new-privileges"
        "--read-only"
        "--tmpfs=/tmp:rw,nosuid,nodev,size=256m"
        "--pids-limit=512"
      ];
    };

    # The image runs as uid 1000 and needs this directory for mutable state.
    systemd.tmpfiles.rules = lib.optionals cfg.enableOmniRoute [
      "d /var/lib/omniroute 0700 1000 1000 -"
    ];

    systemd.services.podman-omniroute = lib.mkIf cfg.enableOmniRoute {
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = lib.mkForce 45;
        UMask = "0077";
        ProtectHome = true;
      };
    };

    services.ollama-webui-lite = lib.mkIf cfg.enableOllamaWebuiLite {
      enable = true;
      package = pkgs._custom.ollama-webui-lite;
      host = wochap-ssc.meta.address;
      port = config._custom.services.web-proxies.ollama-webui-lite.backendPort;
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
      home.packages = [
        voice-clean
      ]
      ++ lib.optionals cfg.enableSupertonic [
        pkgs._custom.supertonic
        tts-clipboard
      ];

      home = {
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
