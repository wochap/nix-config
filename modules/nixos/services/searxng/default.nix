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
  options._custom.services.searxng = {
    enable = lib.mkEnableOption { };
    googleProxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "socks5h://127.0.0.1:1080";
      description = ''
        Optional proxy used only by the Google engine. Prefer an
        unauthenticated local proxy endpoint: values configured here are
        copied to the Nix store.
      '';
    };
  };

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
      redisCreateLocally = true;
      settings = {
        outgoing = {
          request_timeout = 5.0;
          max_request_timeout = 15.0;
          enable_http2 = true;
          retries = 1;
        };
        server = {
          base_url = "https://${proxy.subdomain}.${wochap-ssc.meta.domain}/";
          bind_address = wochap-ssc.meta.address;
          port = proxy.backendPort;
          secret_key = "$SEARX_SECRET_KEY";
          limiter = true;
        };
        search = {
          formats = [
            "html"
            "json"
          ];
          default_lang = "auto";
          autocomplete = "duckduckgo";
        };
        engines = [
          (
            {
              name = "google";
              engine = "google";
              shortcut = "go";
              timeout = 8.0;
              retries = 1;
              retry_on_http_error = [
                403
                429
              ];
              display_error_messages = true;
            }
            // lib.optionalAttrs (cfg.googleProxy != null) {
              proxies."all://" = [ cfg.googleProxy ];
            }
          )
          {
            name = "brave";
            engine = "brave";
            shortcut = "br";
            disabled = false;
          }
          {
            name = "startpage";
            engine = "startpage";
            shortcut = "sp";
            disabled = false;
          }
          {
            name = "mojeek";
            engine = "mojeek";
            shortcut = "mj";
            disabled = false;
          }
        ];
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
