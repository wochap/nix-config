{
  config,
  pkgs,
  lib,
  ...
}:

let
  # TODO: accept this as an option
  inherit (pkgs._custom) wochap-ssc wochap-ssc-home;

  gate = config._custom.services.web-gate;
  remote = config._custom.services.web-proxies-remote;

  # Filter to only act on proxies that are explicitly enabled
  enabledProxies = lib.filterAttrs (name: proxy: proxy.enable) config._custom.services.web-proxies;
  # Subset also served on the LAN under the web-gate domain
  exposedProxies = lib.filterAttrs (name: proxy: proxy.expose.enable) enabledProxies;

  gateLoginPath = "/_gate/login";
  gateTokenFile = "${gate.stateDir}/token.conf";
  gateHtpasswdFile = "${gate.stateDir}/htpasswd";

  # Rotates the gate password + cookie token. Every browser cookie issued
  # before the rotation stops matching $gate_token, so the Basic Auth prompt
  # comes back on the next request.
  web-gate = pkgs.writeShellApplication {
    name = "web-gate";
    runtimeInputs = with pkgs; [
      openssl
      coreutils
      systemd
    ];
    runtimeEnv = {
      GATE_STATE_DIR = gate.stateDir;
      GATE_USER = gate.user;
      GATE_URLS = lib.concatMapStringsSep " " (proxy: "https://${proxy.expose.host}/") (
        lib.attrValues exposedProxies
      );
    };
    text = builtins.readFile ./web-gate.sh;
  };

  # If lazy=true, Nginx hits publicPort (socket proxy).
  # If lazy=false, Nginx hits backendPort (actual app directly).
  mkProxyLocation = proxy: {
    recommendedProxySettings = true;
    proxyPass = "http://${wochap-ssc.meta.address}:${
      toString (if proxy.lazy then proxy.publicPort else proxy.backendPort)
    }";
    proxyWebsockets = true;
    # nginx drops websockets idle for 60s by default; long jobs (e.g. ComfyUI
    # model loads) stay silent longer than that
    extraConfig = ''
      proxy_read_timeout 1h;
      proxy_send_timeout 1h;
    '';
  };

  makeVirtualHost = proxy: {
    forceSSL = true;
    sslTrustedCertificate = "${wochap-ssc}/rootCA.pem";
    sslCertificateKey = "${wochap-ssc}/${wochap-ssc.meta.domain}+4-key.pem";
    sslCertificate = "${wochap-ssc}/${wochap-ssc.meta.domain}+4.pem";
    locations."/" = mkProxyLocation proxy;
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

  # LAN-facing twin of makeVirtualHost under the web-gate domain. The whole
  # vhost sits behind the cookie gate: requests without a cookie matching the
  # current token are bounced to the Basic Auth login location, which hands
  # out the cookie and redirects back.
  makeExternalVirtualHost =
    proxy:
    let
      redirect = "return 302 https://$host${gateLoginPath};";
      proxyLocation = mkProxyLocation proxy;
    in
    {
      onlySSL = true;
      sslTrustedCertificate = "${wochap-ssc-home}/rootCA.pem";
      sslCertificateKey = "${wochap-ssc-home}/${wochap-ssc-home.meta.domain}+4-key.pem";
      sslCertificate = "${wochap-ssc-home}/${wochap-ssc-home.meta.domain}+4.pem";
      listen = [
        {
          addr = gate.listenAddress;
          port = 443;
          ssl = true;
        }
      ];
      # token.conf is written at runtime by web-gate; the glob keeps nginx -t
      # (also run at build time) happy before the file exists.
      extraConfig = ''
        set $gate_token "";
        include ${gate.stateDir}/*.conf;
      '';
      locations = {
        "/" = proxyLocation // {
          extraConfig =
            lib.optionalString proxy.expose.gate ''
              if ($gate_token = "") { ${redirect} }
              if ($cookie_${gate.cookieName} != $gate_token) { ${redirect} }
            ''
            + proxyLocation.extraConfig;
        };
      }
      // lib.optionalAttrs proxy.expose.gate {
        # add_header only applies to 2xx/3xx, so the 401 challenge never
        # leaks the cookie.
        "= ${gateLoginPath}".extraConfig = ''
          auth_basic "wochap gate";
          auth_basic_user_file ${gateHtpasswdFile};
          add_header Set-Cookie "${gate.cookieName}=$gate_token; Path=/; Max-Age=${
            toString (gate.cookieDays * 86400)
          }; Secure; HttpOnly; SameSite=Lax";
          return 302 https://$host/;
        '';
      };
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
            expose = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Also serve this proxy on the LAN as <subdomain>.<web-gate.domain>.";
              };
              gate = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Require the web-gate cookie (Basic Auth once) on the LAN vhost.";
              };
              host = lib.mkOption {
                type = lib.types.str;
                default = "${config.subdomain}.${gate.domain}";
                readOnly = true;
                description = "Hostname of the LAN vhost, for other modules (e.g. allowed origins).";
              };
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

  options._custom.services.web-gate = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = wochap-ssc-home.meta.domain;
      description = "Domain for LAN-exposed proxies; must match the wochap-ssc-home certificate.";
    };
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };
    cookieDays = lib.mkOption {
      type = lib.types.int;
      default = 365;
      description = "Lifetime of the gate cookie. The cookie also dies whenever `web-gate` rotates.";
    };
    cookieName = lib.mkOption {
      type = lib.types.str;
      default = "wochap_gate";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "gate";
      description = "Basic Auth username printed by `web-gate`.";
    };
    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/web-gate";
    };
  };

  options._custom.services.web-proxies-remote = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = { };
    example = {
      "192.168.0.10" = [ "wosarcher" ];
    };
    description = "LAN IP -> subdomains served by another host's web-gate; adds /etc/hosts entries and trusts its CA.";
  };

  config = lib.mkMerge [
    (lib.mkIf (enabledProxies != { }) {
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
              # Restart after daemon-reload instead of stop-then-start. Otherwise a
              # request hitting the socket between the stop and the reload starts
              # the old unit again, and the switch never applies the new one.
              stopIfChanged = false;
            }
          )
        ) (lib.filterAttrs (name: proxy: proxy.serviceScope == "system") enabledProxies));

      # 3. Nginx Virtual Hosts
      services.nginx.virtualHosts =
        lib.mapAttrs' (
          name: proxy:
          lib.nameValuePair "${proxy.subdomain}.${wochap-ssc.meta.domain}" (makeVirtualHost proxy)
        ) enabledProxies
        // lib.mapAttrs' (
          name: proxy: lib.nameValuePair proxy.expose.host (makeExternalVirtualHost proxy)
        ) exposedProxies;

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
    })

    # 6. LAN gate for exposed proxies
    (lib.mkIf (exposedProxies != { }) {
      assertions = [
        {
          assertion = gate.domain == wochap-ssc-home.meta.domain;
          message = "web-gate.domain must match the wochap-ssc-home certificate domain (${wochap-ssc-home.meta.domain})";
        }
      ];

      networking.firewall.allowedTCPPorts = [ 443 ];

      systemd.tmpfiles.rules = [ "d ${gate.stateDir} 0750 root nginx -" ];

      # Seed a random (unknown) password so nginx never starts with an empty
      # htpasswd; `sudo web-gate` prints a usable one.
      systemd.services.web-gate-init = {
        description = "Seed web-gate token and htpasswd";
        before = [ "nginx.service" ];
        wantedBy = [ "nginx.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if [ ! -s ${lib.escapeShellArg gateTokenFile} ] || [ ! -s ${lib.escapeShellArg gateHtpasswdFile} ]; then
            ${lib.getExe web-gate} rotate --quiet --no-reload
          fi
        '';
      };

      environment.systemPackages = [ web-gate ];
    })

    # 7. Client side: reach another host's exposed proxies
    (lib.mkIf (remote != { }) {
      networking.hosts = lib.mapAttrs (ip: subs: map (sub: "${sub}.${gate.domain}") subs) remote;
      security.pki.certificateFiles = [ "${wochap-ssc-home}/rootCA.pem" ];
    })
  ];
}
