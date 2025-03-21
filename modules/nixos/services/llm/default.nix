{ config, pkgs, lib, ... }:

let
  cfg = config._custom.services.llm;
  inherit (pkgs._custom) wochap-ssc;
in {
  imports = [ ./ollama-webui-lite.nix ];

  options._custom.services.llm = {
    enable = lib.mkEnableOption { };
    enableOllama = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
    enableOpenWebui = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    # NOTE: cudaSupport rebuild opencv everytime nixpkgs changes
    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;

    environment.systemPackages = with pkgs; [
      python311Packages.huggingface-hub
      oterm
    ];

    services.ollama = lib.mkIf cfg.enableOllama {
      enable = true;
      package = pkgs.ollama;
      acceleration = lib.mkIf cfg.enableNvidia "cuda";
    };
    systemd.services.ollama.environment.OLLAMA_ORIGINS = "*";

    services.ollama-webui-lite = lib.mkIf cfg.enableOllama {
      enable = true;
      package = pkgs._custom.ollama-webui-lite;
      host = wochap-ssc.meta.address;
      port = 11444;
    };

    services.nginx = {
      enable = true;
      enableReload = true;
      recommendedTlsSettings = true;
    };

    # NOTE: restart after changing certificate
    # you also might need to add certificate to your browsers
    security.pki.certificateFiles = [ "${wochap-ssc}/rootCA.pem" ];

    networking.hosts.${wochap-ssc.meta.address} = [ ]
      ++ lib.optional cfg.enableOllama "ollama.${wochap-ssc.meta.domain}"
      ++ lib.optional cfg.enableOpenWebui "openwebui.${wochap-ssc.meta.domain}";
    services.nginx.virtualHosts = {
      # Make ollama-webui-lite accessible at https://ollama.wochap.local
      "ollama.${wochap-ssc.meta.domain}" = lib.mkIf cfg.enableOllama {
        forceSSL = true;
        sslTrustedCertificate = "${wochap-ssc}/rootCA.pem";
        sslCertificateKey = "${wochap-ssc}/${wochap-ssc.meta.domain}+4-key.pem";
        sslCertificate = "${wochap-ssc}/${wochap-ssc.meta.domain}+4.pem";
        locations."/" = {
          recommendedProxySettings = true;
          proxyPass = "http://${wochap-ssc.meta.address}:${
              toString config.services.ollama-webui-lite.port
            }";
          proxyWebsockets = true;
        };
        listen = [
          {
            addr = wochap-ssc.meta.address;
            port = 443;
            ssl = true;
          }
          {
            addr = wochap-ssc.meta.address;
            port = 80;
          }
        ];
      };
      # Make openwebui accessible at https://openwebui.wochap.local
      # docker run -d -p 127.0.1.1:11454:8080 -e WEBUI_AUTH=False -v open-webui:/app/backend/data --name open-webui ghcr.io/open-webui/open-webui:main
      # docs: https://docs.openwebui.com/getting-started/quick-start/#step-1-pull-the-open-webui-image
      "openwebui.${wochap-ssc.meta.domain}" = lib.mkIf cfg.enableOpenWebui {
        forceSSL = true;
        sslTrustedCertificate = "${wochap-ssc}/rootCA.pem";
        sslCertificateKey = "${wochap-ssc}/${wochap-ssc.meta.domain}+4-key.pem";
        sslCertificate = "${wochap-ssc}/${wochap-ssc.meta.domain}+4.pem";
        locations."/" = {
          recommendedProxySettings = true;
          proxyPass = "http://${wochap-ssc.meta.address}:11454";
          proxyWebsockets = true;
        };
        listen = [
          {
            addr = wochap-ssc.meta.address;
            port = 443;
            ssl = true;
          }
          {
            addr = wochap-ssc.meta.address;
            port = 80;
          }
        ];
      };
    };

    _custom.hm.home.file."Models/.keep".text = "";
  };
}
