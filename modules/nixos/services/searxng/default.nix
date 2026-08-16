{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.searxng;
  inherit (pkgs._custom) wochap-ssc;
  proxy = config._custom.services.web-proxies.searxng;
in
{
  options._custom.services.searxng.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets.local-searxng-secret-key = {
        sopsFile = ../../../../secrets-sops/local.yaml;
        owner = "searx";
        group = "searx";
      };
      templates."searxng.env" = {
        owner = "searx";
        group = "searx";
        mode = "0400";
        content = ''
          SEARX_SECRET_KEY=${config.sops.placeholder.local-searxng-secret-key}
        '';
      };
    };

    services.searx = {
      enable = true;
      environmentFile = config.sops.templates."searxng.env".path;
      limiterSettings.botdetection.ip_lists = {
        pass_ip = [
          "127.0.0.0/8"
          "::1"
        ];
        pass_searxng_org = false;
      };
      openFirewall = false;
      redisCreateLocally = false;
      settings = {
        server = {
          base_url = "https://${proxy.subdomain}.${wochap-ssc.meta.domain}/";
          bind_address = wochap-ssc.meta.address;
          port = proxy.backendPort;
          secret_key = "$SEARX_SECRET_KEY";
          limiter = false;
        };
        search = {
          formats = [
            "html"
            "json"
          ];
          default_lang = "auto";
          autocomplete = "duckduckgo";
        };
      };
    };

    systemd.services = {
      searx-init.serviceConfig = lib._custom.strictNetworkService;

      searx.serviceConfig = lib._custom.strictNetworkService // {
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        MemoryDenyWriteExecute = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
      };
    };

    _custom.services.web-proxies.searxng = {
      enable = true;
      subdomain = "searxng";
      serviceName = "searx";
      publicPort = 8888;
      lazy = true;
    };
  };
}
