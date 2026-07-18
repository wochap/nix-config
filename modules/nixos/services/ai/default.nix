{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (config._custom.globals) configDirectory;
  inherit (pkgs._custom) wochap-ssc;
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
  };

  config = lib.mkIf cfg.enable {
    # NOTE: cudaSupport rebuild opencv everytime nixpkgs changes
    # maybe this is unnecessary for ollama but necessary for docker
    # nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;

    environment.systemPackages =
      with pkgs;
      [
        python314Packages.huggingface-hub
        oterm
      ]
      ++ lib.optionals cfg.enableWhisper [ (whisper-cpp.override { cudaSupport = cfg.enableNvidia; }) ]
      ++ lib.optionals cfg.enablePix2tex [ _custom.pythonPackages.pix2tex ];

    services.ollama = lib.mkIf cfg.enableOllama {
      enable = true;
      package = if cfg.enableNvidia then pkgs.ollama-cuda else pkgs.ollama;
      environmentVariables.OLLAMA_ORIGINS = "*";
    };
    systemd.services.ollama = {
      wantedBy = lib.mkForce [ ];
      # unitConfig.stopWhenUnneeded = true;
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
      home = {
        shellAliases = {
          # transform wav 16kHz to vtt
          wis = "whisper-cli --model ~/Projects/wochap/whisper.cpp/models/ggml-large-v3.bin --output-vtt --file";
          # downloads youtube video and also generates a wav 16kHz format
          ytaw = "yt-dlp -f bestvideo+bestaudio --keep-video --add-metadata --xattrs --merge-output-format mp4 --extract-audio --audio-format wav --postprocessor-args 'ffmpeg:-ar 16000'";
        };

        file = {
          "Models/.keep".text = "";
          ".aider.conf.yml".source =
            lib._custom.relativeSymlink configDirectory ../../../../secrets/dotfiles/aider/.aider.conf.yml;
        };
      };

      programs.zsh.initContent = lib.mkOrder 1000 (builtins.readFile ./dotfiles/whisper.zsh);
    };
  };
}
