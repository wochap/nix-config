{ config, pkgs, lib, ... }:

with lib;
let cfg = config.services.ollama-webui;
in {
  options = {
    services.ollama-webui = {
      enable = mkEnableOption (lib.mdDoc ''
        Ollama-WebUI frontend service for the Ollama backend service.
        It's a single page web application that integrates with Ollama to
        run state-of-the-art AI large language models (LLM) locally with privacy
        on your personal computer.
        It's look and feel is similar to ChatGPT, supports different LLM models,
        it stores chats (in the browser storage), supports image uploads,
        Markdown and Latex rendering etc.See <https://github.com/ollama-webui/ollama-webui>.

        The model names can be looked up on <https://ollama.ai/library> and are available in
        varying sizes to fit your CPU, GPU, RAM and disk storage.

        Required: This module requires the Ollama backend runner service that actually runs the
        LLM models. The Ollama backend can be running locally or on a server; it's available
        as a Nix package or a NixOS module.
        The URL to the Ollama backend service can be set in this module, but overriden
        later in the running Ollama-WebUI as well.

        Optional: This module is configured to run locally, but can be served from a (home) server,
        ideally behind a secured reverse-proxy.
        Look at <https://nixos.wiki/wiki/Nginx> or <https://nixos.wiki/wiki/Caddy>
        on how to set up a reverse proxy.
      '');

      package = mkPackageOption pkgs "ollama-webui" { };

      host = mkOption {
        type = types.str;
        default = "localhost";
        example = "0.0.0.0";
        description = lib.mdDoc ''
          The host/domain name under which the Ollama-WebUI service is reachable.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 11444;
        description = lib.mdDoc "The port for the  Ollama-WebUI service.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description =
          lib.mdDoc "Open ports in the firewall for the Ollama-WebUI service.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.ollama-webui = {
      description = "Ollama WebUI Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = let port = toString cfg.port;
      in {
        ExecStart =
          "${cfg.package}/bin/ollama-webui --port ${port} --address ${cfg.host} --proxy http://${cfg.host}:${port}?";
        DynamicUser = "true";
        Type = "simple";
        Restart = "on-failure";
      };
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
  meta.maintainers = with lib.maintainers; [ malteneuss ];
}
