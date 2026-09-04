{
  config,
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
    services.ollama = {
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
      wantedBy = lib.mkForce (lib.optional cfg.enableOcr "multi-user.target");
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
