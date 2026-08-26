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
            serviceScope = lib.mkOption {
              type = lib.types.enum [
                "system"
                "user"
              ];
              default = "system";
              description = "Whether serviceName belongs to the system or user service manager.";
            };
            userName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "User that owns a user-scoped service.";
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
    assertions = lib.mapAttrsToList (name: proxy: {
      assertion = proxy.serviceScope != "user" || proxy.userName != null;
      message = "web-proxies.${name}: userName is required for user-scoped services";
    }) enabledProxies;

    users.users = lib.foldl' lib.recursiveUpdate { } (
      lib.mapAttrsToList (
        name: proxy:
        lib.optionalAttrs (proxy.lazy && proxy.serviceScope == "user") {
          ${proxy.userName}.linger = true;
        }
      ) enabledProxies
    );

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
            requires = lib.optionals (proxy.serviceScope == "system") [ "${proxy.serviceName}.service" ];
            after = lib.optionals (proxy.serviceScope == "system") [ "${proxy.serviceName}.service" ];
            serviceConfig = {
              ExecStartPre = pkgs.writeShellScript "wait-for-${proxy.serviceName}" ''
                ${lib.optionalString (proxy.serviceScope == "user") ''
                  ${pkgs.systemd}/bin/systemctl --machine=${lib.escapeShellArg "${proxy.userName}@"} --user start ${lib.escapeShellArg "${proxy.serviceName}.service"}
                ''}
                for attempt in {1..120}; do
                  ${lib.getExe pkgs.netcat-openbsd} -z -w 1 ${wochap-ssc.meta.address} ${toString proxy.backendPort} && exit 0
                  ${lib.getExe' pkgs.coreutils "sleep"} 0.5
                done
                echo "Timed out waiting for ${proxy.serviceName} on port ${toString proxy.backendPort}" >&2
                exit 1
              '';
              ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${wochap-ssc.meta.address}:${toString proxy.backendPort}";
            }
            // lib._custom.strictNetworkService
            // {
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
      ) (lib.filterAttrs (name: proxy: proxy.serviceScope == "system") enabledProxies));

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
