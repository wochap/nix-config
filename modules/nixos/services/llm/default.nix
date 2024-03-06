{ config, pkgs, inputs, lib, ... }:

let cfg = config._custom.services.llm;
in {
  options._custom.services.llm = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };
  disabledModules =
    [ "services/misc/ollama.nix" "services/web-apps/ollama-webui.nix" ];
  imports = [
    "${inputs.unstable}/nixos/modules/services/misc/ollama.nix"
    ./ollama-webui.nix
  ];

  config = lib.mkIf cfg.enable {
    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;

    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
    };
    systemd.services.ollama.environment.OLLAMA_ORIGINS = "*";

    services.ollama-webui = {
      enable = true;
      package = pkgs._custom.ollama-webui;
    };

    networking.hosts = { "127.0.0.1" = [ "ollama.wochap.local" ]; };
    security.pki.certificateFiles =
      [ "${pkgs._custom.generated-ssc}/rootCA.pem" ];
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      virtualHosts."ollama.wochap.local" = {
        forceSSL = true;
        sslTrustedCertificate = "${pkgs._custom.generated-ssc}/rootCA.pem";
        sslCertificateKey =
          "${pkgs._custom.generated-ssc}/wochap.local+4-key.pem";
        sslCertificate = "${pkgs._custom.generated-ssc}/wochap.local+4.pem";
        locations."/" = {
          recommendedProxySettings = true;
          proxyPass =
            "http://127.0.0.1:${toString config.services.ollama-webui.port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
