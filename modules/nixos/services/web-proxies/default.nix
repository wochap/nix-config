{
  config,
  pkgs,
  lib,
  ...
}:

let
  # TODO: accept this as an option
  inherit (pkgs._custom) wochap-ssc;

  # Filter to only act on proxies that are explicitly enabled
  enabledProxies = lib.filterAttrs (name: proxy: proxy.enable) config._custom.services.web-proxies;

  # If lazy=true, Nginx hits publicPort (socket proxy).
  # If lazy=false, Nginx hits backendPort (actual app directly).
  makeVirtualHost = proxy: {
    forceSSL = true;
    sslTrustedCertificate = "${wochap-ssc}/rootCA.pem";
    sslCertificateKey = "${wochap-ssc}/${wochap-ssc.meta.domain}+4-key.pem";
    sslCertificate = "${wochap-ssc}/${wochap-ssc.meta.domain}+4.pem";
    locations."/" = {
      recommendedProxySettings = true;
      proxyPass = "http://${wochap-ssc.meta.address}:${
        toString (if proxy.lazy then proxy.publicPort else proxy.backendPort)
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
in
{
  options._custom.services.web-proxies = lib.mkOption {
    description = "Declarative web proxies with optional systemd lazy-loading.";
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }: {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            subdomain = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            serviceName = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            lazy = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            publicPort = lib.mkOption { type = lib.types.port; };
            backendPort = lib.mkOption {
              type = lib.types.port;
              default = config.publicPort + 1;
            };
          };
        }
      )
    );
    default = { };
  };

  config = lib.mkIf (enabledProxies != { }) {
    # 1. Generate systemd sockets for lazy services
    systemd.sockets = lib.mapAttrs' (
      name: proxy:
      lib.nameValuePair "${proxy.serviceName}-proxy" (
        lib.mkIf proxy.lazy {
          description = "Socket for ${proxy.serviceName} proxy";
          wantedBy = [ "sockets.target" ];
          listenStreams = [ "${wochap-ssc.meta.address}:${toString proxy.publicPort}" ];
        }
      )
    ) enabledProxies;

    # 2. Generate socket proxy services and strip wantedBy from actual services
    systemd.services =
      (lib.mapAttrs' (
        name: proxy:
        lib.nameValuePair "${proxy.serviceName}-proxy" (
          lib.mkIf proxy.lazy {
            description = "${proxy.serviceName} socket proxy";
            requires = [ "${proxy.serviceName}.service" ];
            after = [ "${proxy.serviceName}.service" ];
            serviceConfig = {
              ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${wochap-ssc.meta.address}:${toString proxy.backendPort}";
              PrivateTmp = true;
            };
          }
        )
      ) enabledProxies)
      // (lib.mapAttrs' (
        name: proxy:
        lib.nameValuePair proxy.serviceName (
          lib.mkIf proxy.lazy {
            wantedBy = lib.mkForce [ ];
          }
        )
      ) enabledProxies);

    # 3. Nginx Virtual Hosts
    services.nginx.virtualHosts = lib.mapAttrs' (
      name: proxy:
      lib.nameValuePair "${proxy.subdomain}.${wochap-ssc.meta.domain}" (makeVirtualHost proxy)
    ) enabledProxies;

    # 4. Networking hosts mapping
    networking.hosts.${wochap-ssc.meta.address} = lib.mapAttrsToList (
      name: proxy: "${proxy.subdomain}.${wochap-ssc.meta.domain}"
    ) enabledProxies;

    # 5. Core Nginx dependencies
    services.nginx = {
      enable = true;
      enableReload = true;
      recommendedTlsSettings = true;
    };

    # NOTE: restart after changing certificate
    # you also might need to add certificate to your browsers
    security.pki.certificateFiles = [ "${wochap-ssc}/rootCA.pem" ];
  };
}
