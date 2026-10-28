{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.ai;
in
{
  options._custom.services.ai = {
    enableOllama = lib.mkEnableOption { };
    enableOllamaFlashAttention = lib.mkEnableOption { };
  };

  config = lib.mkIf (cfg.enable && cfg.enableOllama) {
    _custom.overlays = [
      (
        final: prev:
        let
          llamaCppVersion = "b11901";
          llamaCppSrc = prev.fetchFromGitHub {
            owner = "ggml-org";
            repo = "llama.cpp";
            tag = llamaCppVersion;
            hash = "sha256-wbTn8xupmmD6ZpvE+l8PlZrstN/7FgGeIXSELQy2gCE=";
          };
          overrideOllama =
            pkg:
            (pkg.override {
              buildGoModule = prev.buildGo127Module;
            }).overrideAttrs
              (oldAttrs: {
                __intentionallyOverridingVersion = true;
                version = "0.40.12";
                src = inputs.ollama;
                vendorHash = "sha256-1mzJrZUHH2ouP6I+LVojHbft7No5AumqKZVq0I/Ubsg=";
                passthru = oldAttrs.passthru // {
                  inherit llamaCppVersion llamaCppSrc;
                };
              });
        in
        {
          ollama = overrideOllama prev.ollama;
          ollama-cpu = overrideOllama prev.ollama-cpu;
          ollama-cuda = overrideOllama prev.ollama-cuda;
          ollama-rocm = overrideOllama prev.ollama-rocm;
          ollama-vulkan = overrideOllama prev.ollama-vulkan;
        }
      )
    ];

    services.ollama = {
      enable = true;
      package =
        if cfg.enableCuda then
          pkgs.ollama-cuda
        else
          (if cfg.enableRocm then pkgs.ollama-rocm else pkgs.ollama);
      environmentVariables = {
        OLLAMA_ORIGINS = "*";
      }
      // lib.optionalAttrs cfg.enableOllamaFlashAttention {
        OLLAMA_FLASH_ATTENTION = "1";
      };
    };

    systemd.services.ollama = {
      wantedBy = lib.mkForce (lib.optional cfg.ocr.enable "multi-user.target");
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

    _custom.hm.home.file."Models/.keep".text = "";
  };
}
