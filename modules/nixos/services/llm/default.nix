{ config, pkgs, inputs, lib, ... }:

let
  cfg = config._custom.services.llm;
  inherit (pkgs._custom) wochap-ssc;
in {
  imports = [ ./ollama-webui-lite.nix ];

  options._custom.services.llm = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    # NOTE: cudaSupport rebuild opencv everytime nixpkgs changes
    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;

    environment.systemPackages = with pkgs; [
      python311Packages.huggingface-hub
      nextstable-nixpkgs.oterm
    ];

    services.ollama = {
      enable = true;
      package = pkgs.prevstable-nixpkgs.ollama;
      acceleration = lib.mkIf cfg.enableNvidia "cuda";
    };
    systemd.services.ollama.environment.OLLAMA_ORIGINS = "*";

    services.ollama-webui-lite = {
      enable = true;
      package = pkgs._custom.ollama-webui-lite;
      host = wochap-ssc.meta.address;
      port = 11444;
    };

    # Make ollama-webui-lite accessible at https://ollama.wochap.local
    # NOTE: restart after changing certificate
    # you also might need to add certificate to your browsers
    networking.hosts.${wochap-ssc.meta.address} =
      [ "ollama.${wochap-ssc.meta.domain}" ];
    security.pki.certificateFiles = [ "${wochap-ssc}/rootCA.pem" ];
    services.nginx = {
      enable = true;
      enableReload = true;
      recommendedTlsSettings = true;
      virtualHosts."ollama.${wochap-ssc.meta.domain}" = {
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
    };

    _custom.hm.home.file."Models/.keep".text = "";
  };
}
