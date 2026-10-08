{
  config,
  pkgs,
  lib,
  ...
}:

# Declarative nginx vhosts for local services, with optional systemd
# socket-activation and an optional LAN gate (Let's Encrypt wildcard cert,
# cookie gate, Cloudflare DDNS). Copy this folder plus
# lib._custom.strictNetworkService, then set `certificate`, plus `domain` and
# `acme.credentialSecret` (sops-nix) for LAN exposure.
# trustedConnections and ddns need NetworkManager and the iptables firewall.
let
  gate = config._custom.services.web-gate;

  # Self-signed certificate package for the local vhosts, built by
  # packages/generate-ssc (mkcert).
  ssc = gate.certificate;
  sscError = "web-gate.certificate must expose meta.address and meta.domain; build it with packages/generate-ssc";
  sscAddress = ssc.meta.address or (throw sscError);
  sscDomain = ssc.meta.domain or (throw sscError);

  # DNS provider API token for lego and DDNS, decrypted by sops-nix.
  tokenFile = config.sops.secrets.${gate.acme.credentialSecret.sopsKey}.path;

  # Filter to only act on proxies that are explicitly enabled
  enabledProxies = lib.filterAttrs (name: proxy: proxy.enable) gate.proxies;
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

  # Opens the LAN port per trusted NetworkManager connection and keeps the
  # DDNS record current. Called from the firewall script and from NM events.
  lanChain = "web-gate-lan";
  restrictLan = gate.trustedConnections != null;
  lanSync = restrictLan || gate.ddns.enable;
  web-gate-lan = pkgs.writeShellApplication {
    name = "web-gate-lan";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
      iproute2
      iptables
      jq
      networkmanager
    ];
    runtimeEnv = {
      LAN_CHAIN = lanChain;
      LAN_PORT = "443";
      LAN_TRUSTED = if restrictLan then lib.concatStringsSep "\n" gate.trustedConnections else "*";
      DDNS_ENABLE = if gate.ddns.enable then "1" else "0";
      DDNS_ZONE = lib.optionalString gate.ddns.enable gate.ddns.zone;
      DDNS_RECORDS = lib.concatStringsSep " " (
        [ "*.${gate.domain}" ] ++ lib.optional gate.ddns.apex gate.domain
      );
      DDNS_TTL = toString gate.ddns.ttl;
      DDNS_TOKEN_FILE = tokenFile;
    };
    text = builtins.readFile ./web-gate-lan.sh;
  };

  # If lazy=true, Nginx hits publicPort (socket proxy).
  # If lazy=false, Nginx hits backendPort (actual app directly).
  mkProxyLocation = proxy: {
    recommendedProxySettings = true;
    proxyPass = "http://${sscAddress}:${
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
    sslTrustedCertificate = "${ssc}/rootCA.pem";
    sslCertificateKey = "${ssc}/${sscDomain}+4-key.pem";
    sslCertificate = "${ssc}/${sscDomain}+4.pem";
    locations."/" = mkProxyLocation proxy;
    listen = [
      {
        addr = sscAddress;
        port = 443;
        ssl = true;
      }
      {
        addr = sscAddress;
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
      useACMEHost = gate.domain;
      basicAuthFile = proxy.expose.basicAuthFile;
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
          auth_basic "${gate.realm}";
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
  options._custom.services.web-gate = {
    certificate = lib.mkOption {
      type = lib.types.package;
      example = lib.literalExpression ''
        pkgs.callPackage ./generate-ssc { } {
          domain = "example.local";
          address = "127.0.1.1";
        }
      '';
      description = ''
        Self-signed certificate for the local vhosts, built by
        packages/generate-ssc. The module reads `meta.address` (listen and
        backend address, /etc/hosts entry), `meta.domain` (local vhosts are
        `<subdomain>.<meta.domain>`) and the mkcert files `rootCA.pem`,
        `<domain>+4.pem` and `<domain>+4-key.pem`. The `+4` suffix comes from
        the 5 names generate-ssc passes to mkcert.
      '';
    };
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      example = "home.example.com";
      description = ''
        Domain for LAN-exposed proxies. A public DNS record `*.<domain>` must
        point at this host's LAN IP; nginx serves a Let's Encrypt wildcard
        certificate for it, obtained through the DNS-01 challenge.
      '';
    };
    acme = {
      dnsProvider = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "cloudflare";
        description = "lego DNS provider that answers the DNS-01 challenge.";
      };
      dnsResolver = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        # The local resolver may answer from cache; ask a public one whether
        # the challenge record has propagated.
        default = "1.1.1.1:53";
        description = "Resolver lego uses to check challenge propagation.";
      };
      credentialSecret.sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "SOPS file containing the DNS provider API token.";
      };
      credentialSecret.sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "cloudflare-dns-api-token";
        description = "Key containing the DNS provider API token in the SOPS file.";
      };
      credentialSecret.variable = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "CLOUDFLARE_DNS_API_TOKEN";
        description = "lego environment variable the token feeds; it is passed as `<variable>_FILE`.";
      };
    };
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };
    trustedConnections = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.nonEmptyStr);
      default = null;
      example = [
        "Home WiFi"
        "Wired connection 1"
      ];
      description = ''
        NetworkManager connection names or UUIDs on which port 443 opens for
        exposed proxies. On any other network the LAN vhosts stay unreachable.
        null opens the port on every interface, for hosts that never move.
      '';
    };
    ddns = {
      enable = lib.mkEnableOption "updating the `*.<domain>` Cloudflare A record to this host's LAN IP on every network change";
      zone = lib.mkOption {
        type = lib.types.nonEmptyStr;
        example = "example.com";
        description = "Cloudflare zone that contains `domain`.";
      };
      apex = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Also point `<domain>` itself at this host, e.g. for SSH or remote builds.";
      };
      ttl = lib.mkOption {
        type = lib.types.ints.between 60 86400;
        default = 60;
        description = "TTL of the A record. Short, so clients follow the host between networks.";
      };
    };
    cookieDays = lib.mkOption {
      type = lib.types.int;
      default = 365;
      description = "Lifetime of the gate cookie. The cookie also dies whenever `web-gate` rotates.";
    };
    cookieName = lib.mkOption {
      type = lib.types.str;
      default = "web_gate";
    };
    realm = lib.mkOption {
      type = lib.types.str;
      default = "web-gate";
      description = "Basic Auth realm shown in the browser's login prompt.";
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

    proxies = lib.mkOption {
      description = "Declarative web proxies with optional systemd lazy-loading.";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }: {
            options = {
              enable = lib.mkEnableOption { };
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
              lazy = lib.mkEnableOption { };
              expose = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Also serve this proxy on the LAN as <subdomain>.<web-gate.domain>.";
                };
                gate = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Require the web-gate cookie (Basic Auth once) on the LAN vhost.";
                };
                basicAuthFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = ''
                    htpasswd file, readable by nginx, that protects the LAN vhost
                    with plain Basic Auth. For clients that cannot follow the
                    gate's cookie redirect but can send credentials, such as Nix
                    through a netrc file.
                  '';
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
  };

  config = lib.mkMerge [
    (lib.mkIf (enabledProxies != { }) {
      assertions = lib.mapAttrsToList (name: proxy: {
        assertion = proxy.serviceScope != "user" || proxy.userName != null;
        message = "web-gate.proxies.${name}: userName is required for user-scoped services";
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
            listenStreams = [ "${sscAddress}:${toString proxy.publicPort}" ];
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
                    ${lib.getExe pkgs.netcat-openbsd} -z -w 1 ${sscAddress} ${toString proxy.backendPort} && exit 0
                    ${lib.getExe' pkgs.coreutils "sleep"} 0.5
                  done
                  echo "Timed out waiting for ${proxy.serviceName} on port ${toString proxy.backendPort}" >&2
                  exit 1
                '';
                ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${sscAddress}:${toString proxy.backendPort}";
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
          name: proxy: lib.nameValuePair "${proxy.subdomain}.${sscDomain}" (makeVirtualHost proxy)
        ) enabledProxies
        // lib.mapAttrs' (
          name: proxy: lib.nameValuePair proxy.expose.host (makeExternalVirtualHost proxy)
        ) exposedProxies;

      # 4. Networking hosts mapping
      networking.hosts.${sscAddress} = lib.mapAttrsToList (
        name: proxy: "${proxy.subdomain}.${sscDomain}"
      ) enabledProxies;

      # 5. Core Nginx dependencies
      services.nginx = {
        enable = true;
        enableReload = true;
        recommendedTlsSettings = true;
      };

      # NOTE: restart after changing certificate
      # you also might need to add certificate to your browsers
      security.pki.certificateFiles = [ "${ssc}/rootCA.pem" ];
    })

    # 6. LAN gate for exposed proxies
    (lib.mkIf (exposedProxies != { }) {
      sops.secrets.${gate.acme.credentialSecret.sopsKey}.sopsFile = gate.acme.credentialSecret.sopsFile;

      # One wildcard certificate for every exposed vhost. DNS-01 needs no
      # inbound port, so the host stays LAN-only.
      security.acme = {
        acceptTerms = true;
        certs.${gate.domain} = {
          domain = "*.${gate.domain}";
          group = config.services.nginx.group;
          inherit (gate.acme) dnsProvider dnsResolver;
          credentialFiles."${gate.acme.credentialSecret.variable}_FILE" = tokenFile;
        };
      };

      assertions =
        lib.mapAttrsToList (name: proxy: {
          assertion = !(proxy.expose.gate && proxy.expose.basicAuthFile != null);
          message = "web-gate.proxies.${name}: expose.gate and expose.basicAuthFile are mutually exclusive";
        }) exposedProxies
        ++ [
          {
            assertion = !gate.ddns.enable || gate.acme.dnsProvider == "cloudflare";
            message = "web-gate.ddns only supports Cloudflare (web-gate.acme.dnsProvider)";
          }
          {
            assertion = !lanSync || config.networking.networkmanager.enable;
            message = "web-gate.trustedConnections and web-gate.ddns need NetworkManager";
          }
          {
            assertion = !restrictLan || !config.networking.nftables.enable;
            message = "web-gate.trustedConnections supports the iptables firewall backend only";
          }
        ];

      networking.firewall =
        if restrictLan then
          {
            # The chain is filled by web-gate-lan; jump to it before the final
            # refuse rule. ACCEPT instead of nixos-fw-accept, so the chain never
            # blocks the firewall from deleting its own chains on reload.
            extraCommands = ''
              ip46tables -N ${lanChain} 2>/dev/null || true
              ip46tables -A nixos-fw -j ${lanChain}
              ${lib.getExe web-gate-lan} firewall || true
            '';
            extraStopCommands = ''
              ip46tables -F ${lanChain} 2>/dev/null || true
            '';
          }
        else
          {
            allowedTCPPorts = [ 443 ];
          };

      systemd.services.web-gate-lan = lib.mkIf lanSync {
        description = "Sync LAN exposure and DDNS with the active network";
        after = [
          "firewall.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        # Also catches missed NM events and failed API calls.
        startAt = "hourly";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe web-gate-lan} sync";
        };
      };

      networking.networkmanager.dispatcherScripts = lib.optional lanSync {
        type = "basic";
        source = pkgs.writeShellScript "web-gate-lan-dispatch" ''
          # NetworkManager passes the interface as $1 and the action as $2.
          case "$2" in
            up | down | dhcp4-change | connectivity-change)
              ${pkgs.systemd}/bin/systemctl restart --no-block web-gate-lan.service
              ;;
          esac
        '';
      };

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

      environment.systemPackages = [ web-gate ] ++ lib.optional lanSync web-gate-lan;
    })
  ];
}
