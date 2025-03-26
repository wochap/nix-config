{ config, pkgs, lib, ... }:

let
  cfg = config._custom.services.llm;
  inherit (config._custom.globals) configDirectory;
  inherit (pkgs._custom) wochap-ssc;
  makeVirtualHost = port: {
    forceSSL = true;
    sslTrustedCertificate = "${wochap-ssc}/rootCA.pem";
    sslCertificateKey = "${wochap-ssc}/${wochap-ssc.meta.domain}+4-key.pem";
    sslCertificate = "${wochap-ssc}/${wochap-ssc.meta.domain}+4.pem";
    locations."/" = {
      recommendedProxySettings = true;
      proxyPass = "http://${wochap-ssc.meta.address}:${toString port}";
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
in {
  imports = [ ./ollama-webui-lite.nix ];

  options._custom.services.llm = {
    enable = lib.mkEnableOption { };
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

    environment.systemPackages = with pkgs; [
      python311Packages.huggingface-hub
      oterm
    ];

    services.ollama = lib.mkIf cfg.enableOllama {
      enable = true;
      package = pkgs.nixpkgs-unstable.ollama;
      acceleration = lib.mkIf cfg.enableNvidia "cuda";
    };
    systemd.services.ollama.environment.OLLAMA_ORIGINS = "*";

    services.ollama-webui-lite = lib.mkIf cfg.enableOllamaWebuiLite {
      enable = true;
      package = pkgs._custom.ollama-webui-lite;
      host = wochap-ssc.meta.address;
      port = 11444;
    };

    services.nextjs-ollama-llm-ui.enable =
      lib.mkIf cfg.enableNextjsOllamaLlmUi {
        enable = true;
        package = pkgs.nixpkgs-unstable.nextjs-ollama-llm-ui;
        hostname = wochap-ssc.meta.address;
        port = 11464;
      };

    services.open-webui = lib.mkIf cfg.enableOllama {
      enable = true;
      package = pkgs.nixpkgs-unstable.open-webui;
      openFirewall = false;
      host = wochap-ssc.meta.address;
      port = 11454;
      environment = { WEBUI_AUTH = "False"; };
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
      ++ lib.optional cfg.enableOllamaWebuiLite
      "ollama.${wochap-ssc.meta.domain}"
      ++ lib.optional cfg.enableNextjsOllamaLlmUi
      "nolui.${wochap-ssc.meta.domain}"
      ++ lib.optional cfg.enableOpenWebui "openwebui.${wochap-ssc.meta.domain}";

    services.nginx.virtualHosts = {
      # Make ollama-webui-lite accessible at https://ollama.wochap.local
      "ollama.${wochap-ssc.meta.domain}" = lib.mkIf cfg.enableOllamaWebuiLite
        (makeVirtualHost config.services.ollama-webui-lite.port);

      # Make nextjs-ollama-llm-ui accessible at https://nolui.wochap.local
      "nolui.${wochap-ssc.meta.domain}" = lib.mkIf cfg.enableNextjsOllamaLlmUi
        (makeVirtualHost config.services.nextjs-ollama-llm-ui.port);

      # Make openwebui accessible at https://openwebui.wochap.local
      "openwebui.${wochap-ssc.meta.domain}" = lib.mkIf cfg.enableOpenWebui
        (makeVirtualHost config.services.open-webui.port);
    };

    _custom.hm = {
      home.file = {
        "Models/.keep".text = "";
        ".aider.conf.yml".source = lib._custom.relativeSymlink configDirectory
          ../../../../secrets/dotfiles/aider/.aider.conf.yml;
      };
    };
  };
}
