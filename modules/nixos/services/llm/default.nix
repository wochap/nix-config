{ config, pkgs, inputs, lib, ... }:

let cfg = config._custom.services.llm;
in {
  imports = [ ./ollama-webui-lite.nix ];

  options._custom.services.llm = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;

    environment.systemPackages = with pkgs; [
      python311Packages.huggingface-hub
      oterm
    ];

    services.ollama = {
      enable = true;
      package = pkgs.ollama;
      acceleration = lib.mkIf cfg.enableNvidia "cuda";
    };
    systemd.services.ollama.environment.OLLAMA_ORIGINS = "*";

    services.ollama-webui-lite = {
      enable = true;
      package = pkgs._custom.ollama-webui-lite;
    };

    # Make ollama-webui-lite accessible at https://ollama.wochap.local
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
          proxyPass = "http://127.0.0.1:${
              toString config.services.ollama-webui-lite.port
            }";
          proxyWebsockets = true;
        };
      };
    };

    _custom.hm.home.file."Models/.keep".text = "";
  };
}
